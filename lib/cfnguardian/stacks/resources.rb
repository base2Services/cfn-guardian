require 'cfndsl'

module CfnGuardian
  module Stacks
    class Resources
      include CfnDsl::CloudFormation
      
      def build_template(resources)
        @template = CloudFormation("Guardian nested stack")
        
        %w(Critical Warning Task Informational).each do |name|
          parameter = @template.Parameter(name)
          parameter.Type 'String'
          parameter.Description "SNS topic ARN for #{name} notifications"
        end
        
        maintenance_parameter = @template.Parameter('EnableMaintenance')
        maintenance_parameter.Type 'String'
        maintenance_parameter.Description 'Enable alarm maintenance'
        maintenance_parameter.AllowedValues ['true','false']
        maintenance_parameter.Default 'false'
        
        resources.each do |resource|
          case resource[:type]
          when 'Alarm'
            add_alarm(resource)
          when 'Event'
            add_event(resource)
          else
            puts "Warn: #{resource[:type]} is a unsuported resource type"
          end
        end
        
        return @template
      end
      
      def add_alarm(resource)
        @template.declare do
          CloudWatch_Alarm("#{resource[:resource_name]}#{resource[:class]}#{resource[:name]}#{resource[:type]}"[0..255]) do
            ActionsEnabled resource[:maintenance] ? Ref('EnableMaintenance') : true
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
            DatapointsToAlarm resource[:datapoints_to_alarm] unless resource[:datapoints_to_alarm].nil?
            ExtendedStatistic resource[:extended_statistic] unless resource[:extended_statistic].nil?
            EvaluateLowSampleCountPercentile resource[:evaluate_low_sample_count_percentile] unless resource[:evaluate_low_sample_count_percentile].nil?
            Unit resource[:unit] unless resource[:unit].nil?
          end
        end
      end
      
      def add_event(resource)
        @template.declare do
          Parameter("#{resource[:target]}#{resource[:environment]}") do
            Type 'String'
            Description "Lamba funtion Arn for #{resource[:class]} #{resource[:type]}"
          end
          
          Events_Rule("#{resource[:class]}#{resource[:type]}#{resource[:hash]}"[0..255]) do
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
          end
        end
      end
      
    end
  end
end
