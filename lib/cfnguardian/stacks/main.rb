require 'cfndsl'

module CfnGuardian
  module Stacks
    class Main
      include CfnDsl::CloudFormation
      
      def build_template(stacks,checks)
        @template = CloudFormation("Guardian main stack")
        
        %w(Critical Warning Task Informational).each do |name|
          parameter = @template.Parameter(name)
          parameter.Type 'String'
          parameter.Description "SNS topic ARN for #{name} notifications"
        end
        
        parameters = {
          Critical: Ref(:Critical),
          Warning: Ref(:Warning),
          Task: Ref(:Task),
          Informational: Ref(:Informational)
        }
        
        build_iam_role()
        
        checks.each {|check| parameters["#{check[:name]}Function#{check[:environment]}"] = add_lambda(check)}
        stacks.each {|stack| add_stack(stack['Name'],stack['TemplateURL'],parameters)}
        
        return @template
      end
      
      def build_iam_role()
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
            Path '/'
            Policies([
              {
                PolicyName: 'logging',
                PolicyDocument: {
                  Version: '2012-10-17',
                  Statement: [{
                    Effect: 'Allow',
                    Action: [ 'logs:CreateLogGroup', 'logs:CreateLogStream', 'logs:PutLogEvents' ],
                    Resource: 'arn:aws:logs:*:*:*'
                  }]
                }
              },
              {
                PolicyName: 'metrics',
                PolicyDocument: {
                  Version: '2012-10-17',
                  Statement: [{
                    Effect: 'Allow',
                    Action: [ 'cloudwatch:PutMetricData' ],
                    Resource: '*'
                  }]
                }
              },
              {
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
            ])
            Tags([
              { Key: 'Name', Value: 'guardian-lambda-role' },
              { Key: 'Environment', Value: 'guardian' }
            ])
          end
        end
      end
      
      def add_lambda(check)
        vpc_config = {}
        
        if check.has_key?(:vpc)
          @template.declare do
            EC2_SecurityGroup("#{check[:name]}SecurityGroup#{check[:environment]}") do
              VpcId check[:vpc]
              GroupDescription "Guardian lambda function #{check[:class]} check"
              Tags([
                { Key: 'Name', Value: "guardian-#{check[:name]}-#{check[:environment]}" },
                { Key: 'Environment', Value: 'guardian' }
              ])
            end
          end
          
          vpc_config[:SecurityGroupIds] = Ref("#{check[:name]}SecurityGroup#{check[:environment]}")
          vpc_config[:SubnetIds] = check[:subnets]
        end
        
        @template.declare do
          Lambda_Function("#{check[:name]}Function#{check[:environment]}") do
            Code({ 
              S3Bucket: FnSub("base2.lambda.${AWS::Region}"), 
              S3Key: "#{check[:package]}/#{check[:version]}/handler.zip"
            })
            Handler check[:handler]
            MemorySize 128
            Runtime check[:runtime]
            Timeout 120
            Role FnGetAtt(:LambdaExecutionRole, :Arn)
            VpcConfig vpc_config unless vpc_config.empty?
            Tags([
              { Key: 'Name', Value: "guardian-#{check[:name]}-#{check[:class]}" },
              { Key: 'Environment', Value: 'guardian' }
            ])
          end
          
          Lambda_Permission("#{check[:name]}Permissions#{check[:environment]}") do
            FunctionName Ref("#{check[:name]}Function#{check[:environment]}")
            Action 'lambda:InvokeFunction'
            Principal 'events.amazonaws.com'
          end
        end

        return FnGetAtt("#{check[:name]}Function#{check[:environment]}", :Arn)
      end
      
      def add_stack(name,url,stack_parameters)
        @template.declare do
          CloudFormation_Stack(name) do
            Parameters stack_parameters
            TemplateURL url
            TimeoutInMinutes 15
            Tags([
              { Key: 'Name', Value: "guardian-stack-#{name}" }
            ])
          end
        end
      end
      
    end
  end
end