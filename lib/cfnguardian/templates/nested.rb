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
  
  resources = external_parameters.fetch(:resources, [])

  resources.each do |resource|
    
    case resource[:type]
    when 'Alarm'

      CloudWatch_Alarm("#{resource[:resource]}#{resource[:class]}#{resource[:name]}#{resource[:type]}"[0..255]) {
        ActionsEnabled true
        AlarmDescription "Guardian alarm #{resource[:class]} #{resource[:resource]} #{resource[:name]}"
        AlarmName "#{resource[:class]}-#{resource[:resource]}-#{resource[:name]}"
        ComparisonOperator resource[:comparison_operator]
        Dimensions resource[:dimensions].map {|k,v| {Name: k, Value: v}}
        EvaluationPeriods resource[:evaluation_periods]
        Statistic resource[:statistic]
        Period resource[:period]
        Threshold resource[:threshold]
        MetricName resource[:metric_name]
        Namespace resource[:namespace]
        AlarmActions [Ref(resource[:alarm_action])]
        OKActions [Ref(resource[:alarm_action])]
        TreatMissingData resource[:treat_missing_data] unless resource[:treat_missing_data].nil?
      }
      
    when 'Event'
      
      Parameter(resource[:target]) {
        Type 'String'
        Description "Lamba funtion Arn for #{resource[:class]} #{resource[:type]}"
      }
      
      Events_Rule("#{resource[:class]}#{resource[:type]}#{resource[:hash]}"[0..255]) {
        State 'ENABLED'
        Description "Guardian scheduled #{resource[:class]} #{resource[:type]}"
        ScheduleExpression "cron(#{resource[:cron]})"
        Targets([
          {
            Arn: Ref(resource[:target]),
            Id: resource[:hash],
            Input: FnSub(resource[:payload])
          }
        ])
      }
      
    else
      puts "Warn: #{resource[:type]} is a unsuported resource type"
    end
    
  end
  
end
