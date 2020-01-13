require 'cfndsl'

CloudFormation do
  
  Description("CFN Guardian")

  Parameter(:Critical) {
    Type 'String'
    Description 'SNS Topic Arn for critical notifications'
  }
  
  Parameter(:Warning) {
    Type 'String'
    Description 'SNS Topic Arn for warning notifications'
  }
  
  Parameter(:Task) {
    Type 'String'
    Description 'SNS Topic Arn for task notifications'
  }
  
  Parameter(:Informational) {
    Type 'String'
    Description 'SNS Topic Arn for informational notifications'
  }
  
  stack_parameters = {
    Critical: Ref(:Critical),
    Warning: Ref(:Warning),
    Task: Ref(:Task),
    Informational: Ref(:Informational)
  }
  
  if external_parameters[:checks].any?
    
    IAM_Role(:LambdaExecutionRole) {
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
    }
    
    external_parameters[:checks].each do |check|
      
      vpc_config = {}
      
      if check.has_key?(:vpc)
        EC2_SecurityGroup("#{check[:name]}SecurityGroup#{check[:environment]}") {
          VpcId check[:vpc]
          GroupDescription "Guardian lambda function #{check[:class]} check"
        }
        
        vpc_config[:SecurityGroupIds] = Ref("#{check[:name]}SecurityGroup#{check[:environment]}")
        vpc_config[:SubnetIds] = check[:subnets]
      end
      
      Lambda_Function("#{check[:name]}Function#{check[:environment]}") {
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
      }

      Lambda_Permission("#{check[:name]}Permissions#{check[:environment]}") {
        FunctionName Ref("#{check[:name]}Function#{check[:environment]}")
        Action 'lambda:InvokeFunction'
        Principal 'events.amazonaws.com'
      }
      
      stack_parameters["#{check[:name]}Function#{check[:environment]}"] = FnGetAtt("#{check[:name]}Function#{check[:environment]}", :Arn)
    end
  end
  
  stacks = external_parameters.fetch(:stacks, [])
  
  stacks.each do |stack|
    CloudFormation_Stack(stack['Name']) {
      Parameters stack_parameters
      TemplateURL stack['TemplateURL']
      TimeoutInMinutes 15
    }
  end
  
end
