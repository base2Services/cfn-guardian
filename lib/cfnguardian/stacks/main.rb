require 'cfndsl'

module CfnGuardian
  module Stacks
    class Main
      include CfnDsl::CloudFormation
      include Logging
      
      attr_reader :template
      
      def initialize()
        @parameters = []
        @template = CloudFormation("Guardian main stack")
      end
      
      def build_template(stacks,checks,topics,maintenance_groups,ssm_parameters)     
        parameters = {}
           
        topics.each do |name, sns|
          parameter = @template.Parameter(name)
          parameter.Type 'String'
          parameter.Description "SNS topic ARN for #{name} notifications"
          parameter.Default sns
          parameters[name] = Ref(name)
        end

        if maintenance_groups.any?
          add_lambda(CfnGuardian::Models::MaintenanceGroupCheck.new(maintenance_groups))
          maintenance_groups.each {|group,config| add_maintenance_group(group,config,parameters)}
        end
        
        add_iam_role(ssm_parameters)
                
        checks.each {|check| parameters["#{check.name}Function#{check.environment}"] = add_lambda(check)}
        stacks.each {|stack| add_stack(stack['Name'],stack['TemplateURL'],parameters,stack['Reference'])}        
      end
      
      def add_iam_role(ssm_parameters)
        policies = []
        policies << {
          PolicyName: 'logging',
          PolicyDocument: {
            Version: '2012-10-17',
            Statement: [{
              Effect: 'Allow',
              Action: [ 'logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents' ],
              Resource: 'arn:aws:logs:*:*:*'
            }]
          }
        }
        policies << {
          PolicyName: 'metrics',
          PolicyDocument: {
            Version: '2012-10-17',
            Statement: [{
              Effect: 'Allow',
              Action: [ 'cloudwatch:PutMetricData' ],
              Resource: '*'
            }]
          }
        }
        policies << {
          PolicyName: 'attach-network-interface',
          PolicyDocument: {
            Version: '2012-10-17',
            Statement: [{
              Effect: 'Allow',
              Action: [ 'ec2:CreateNetworkInterface', 'ec2:DescribeNetworkInterfaces', 'ec2:DeleteNetworkInterface' ],
              Resource: '*'
            }]
          }
        }
        policies << {
          PolicyName: 'maintenance-group-actions',
          PolicyDocument: {
            Version: '2012-10-17',
            Statement: [{
              Effect: 'Allow',
              Action: [ 'cloudwatch:DescribeAlarms', 'cloudwatch:DisableAlarmActions', 'cloudwatch:EnableAlarmActions', 'cloudwatch:SetAlarmState' ],
              Resource: FnSub("arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:*")
            }]
          }
        }
        if ssm_parameters.any?
          policies << {
            PolicyName: 'ssm-parameters',
            PolicyDocument: {
              Version: '2012-10-17',
              Statement: [{
                Effect: 'Allow',
                Action: [ 'ssm:GetParameter', 'ssm:GetParametersByPath', 'ssm:GetParameters' ],
                Resource: ssm_parameters.map {|param| FnSub("arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter#{param}") }
              }]
            }
          }
        end
        @template.declare do
          IAM_Role(:LambdaExecutionRole) do
            AssumeRolePolicyDocument({
              Version: '2012-10-17',
              Statement: [{
                Effect: 'Allow',
                Principal: { Service: [ 'lambda.amazonaws.com' ] },
                Action: [ 'sts:AssumeRole' ]
              }]
            })
            Path '/guardian/'
            Policies(policies)
            Tags([
              { Key: 'Name', Value: 'guardian-lambda-role' },
              { Key: 'Environment', Value: 'guardian' }
            ])
          end
        end
      end
      
      def add_lambda(check)
        vpc_config = {}
        if !check.vpc.nil?
          @template.declare do
            EC2_SecurityGroup("#{check.name}SecurityGroup#{check.environment}") do
              VpcId check.vpc
              GroupDescription "Guardian lambda function #{check.group} check"
              Tags([
                { Key: 'Name', Value: "guardian-#{check.name}-#{check.environment}" },
                { Key: 'Environment', Value: 'guardian' }
              ])
            end
          end
          
          vpc_config[:SecurityGroupIds] = [Ref("#{check.name}SecurityGroup#{check.environment}")]
          vpc_config[:SubnetIds] = check.subnets
        end
        
        @template.declare do
          Lambda_Function("#{check.name}Function#{check.environment}") do
            Code({ 
              S3Bucket: FnSub("base2.guardian.lambda.checks.${AWS::Region}"), 
              S3Key: "#{check.package}/#{check.branch}/#{check.version}.zip"
            })
            Handler check.handler
            MemorySize check.memory
            Runtime check.runtime
            Timeout check.timeout
            Role FnGetAtt(:LambdaExecutionRole, :Arn)
            VpcConfig vpc_config unless vpc_config.empty?
            Tags([
              { Key: 'Name', Value: "guardian-#{check.name}-#{check.group}" },
              { Key: 'Environment', Value: 'guardian' }
            ])
          end
          
          Lambda_Permission("#{check.name}Permissions#{check.environment}") do
            FunctionName Ref("#{check.name}Function#{check.environment}")
            Action 'lambda:InvokeFunction'
            Principal 'events.amazonaws.com'
          end
        end

        return FnGetAtt("#{check.name}Function#{check.environment}", :Arn)
      end
      
      def add_stack(name,url,stack_parameters,stack_id)
        @template.declare do
          CloudFormation_Stack(name) do
            Parameters stack_parameters
            TemplateURL url
            TimeoutInMinutes 15
            Tags([
              { Key: 'Name', Value: "guardian-stack-#{name}" },
              { Key: 'guardian:stack-id', Value: "stk#{stack_id}"}
            ])
          end
        end
      end

      def add_maintenance_group(group,config,parameters)
        group_name = "#{group}MaintenanceGroup"
        schedules = config.fetch('Schedules', {})
        logging = config.dig('Schedules', 'Debug').to_s

        topic = @template.SNS_Topic(group_name)
        topic.TopicName group_name
        topic.Tags([{ Key: 'Environment', Value: 'guardian' }])
        parameters[group_name] = Ref(group_name)

        if schedules.any?
          event = @template.Events_Rule("#{group_name}EnableEvent")
          event.Name "#{group_name}EnableEvent"
          event.ScheduleExpression "cron(#{schedules['Enable']})"
          event.Targets([{ 
            Arn: FnGetAtt('MaintenanceGroupCheckFunction', 'Arn'), 
            Id: "#{group_name}EnableTarget", 
            Input: {action:"enable_alarms", maintenance_group: group_name, logging: logging}.to_json
          }])

          event = @template.Events_Rule("#{group_name}DisableEvent")
          event.Name "#{group_name}DisableEvent"
          event.ScheduleExpression "cron(#{schedules['Disable']})"            
          event.Targets([{ 
            Arn: FnGetAtt('MaintenanceGroupCheckFunction', 'Arn'), 
            Id: "#{group_name}DisableTarget", 
            Input: {action:"disable_alarms", maintenance_group: group_name, logging: logging}.to_json
          }])
        end
      end
    end
  end
end
