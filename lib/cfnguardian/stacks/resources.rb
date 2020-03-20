require 'cfndsl'
require 'digest/md5'
require 'cfnguardian/cloudwatch'

module CfnGuardian
  module Stacks
    class Resources
      include CfnDsl::CloudFormation
      
      def build_template(resources,maintenance_groups)
        @template = CloudFormation("Guardian nested stack")
        
        %w(Critical Warning Task Informational).each do |name|
          parameter = @template.Parameter(name)
          parameter.Type 'String'
        end
        
        maintenance_groups.each do |group|
          parameter = @template.Parameter(group)
          parameter.Type 'String'
        end
        
        resources.each do |resource|
          case resource.type
          when 'Alarm'
            add_alarm(resource)
          when 'Event'
            add_event(resource)
          when 'Composite'
            add_composite_alarm(resource)
          when 'MetricFilter'
            add_metric_filter(resource)
          else
            puts "Warn: #{resource.type} is a unsuported resource type"
          end
        end
        
        return @template
      end

      def add_alarm(alarm)
        actions = [Ref(alarm.alarm_action)]
        actions.concat alarm.maintenance_groups.map {|mg| Ref(mg)} if alarm.maintenance_groups.any?

        @template.declare do
          CloudWatch_Alarm("#{alarm.resource_hash}#{alarm.group}#{alarm.name}#{alarm.type}"[0..255]) do
            ActionsEnabled true
            AlarmDescription "Guardian alarm #{alarm.name} for the resource #{alarm.resource_id} in alarm group #{alarm.group}"
            AlarmName CfnGuardian::CloudWatch.get_alarm_name(alarm)
            ComparisonOperator alarm.comparison_operator
            Dimensions alarm.dimensions.map {|k,v| {Name: k, Value: v}} if alarm.dimensions.any?
            EvaluationPeriods alarm.evaluation_periods
            Statistic alarm.statistic
            Period alarm.period
            Threshold alarm.threshold
            MetricName alarm.metric_name
            Namespace alarm.namespace
            AlarmActions actions
            OKActions actions
            TreatMissingData alarm.treat_missing_data unless alarm.treat_missing_data.nil?
            DatapointsToAlarm alarm.datapoints_to_alarm unless alarm.datapoints_to_alarm.nil?
            ExtendedStatistic alarm.extended_statistic unless alarm.extended_statistic.nil?
            EvaluateLowSampleCountPercentile alarm.evaluate_low_sample_count_percentile unless alarm.evaluate_low_sample_count_percentile.nil?
            Unit alarm.unit unless alarm.unit.nil?
          end
        end
      end
      
      def add_event(event)
        @template.declare do
          Parameter(event.target) do
            Type 'String'
            Description "Lambda function Arn for #{event.group} #{event.type}"
          end
          
          Events_Rule("#{event.group}#{event.type}#{event.hash}"[0..255]) do
            State 'ENABLED'
            Description "Guardian scheduled #{event.group} #{event.type}"
            ScheduleExpression "cron(#{event.cron})"
            Targets([
              { 
                Arn: Ref(event.target),
                Id: event.hash,
                Input: FnSub(event.payload)
              }
            ])
          end
        end
      end
      
      def add_composite_alarm(alarm)
        @template.declare do
          CloudWatch_CompositeAlarm(alarm.name) do
            
            AlarmDescription alarm.description
            AlarmName "guardian-#{alarm.name}"
            AlarmRule alarm.rule
            
            unless alarm.alarm_action.nil?
              ActionsEnabled true
              AlarmActions [Ref(alarm.alarm_action)]
              # InsufficientDataActions [Ref(alarm.alarm_action)]
              # OKActions [Ref(alarm.alarm_action)]
            end
            
          end
        end
      end
      
      def add_metric_filter(filter)
        @template.declare do
          Logs_MetricFilter("#{filter.name}#{filter.type}") do
            LogGroupName filter.log_group
            FilterPattern filter.pattern
            MetricTransformations([
              {
                MetricValue: filter.metric_value,
                MetricName: filter.metric_name,
                MetricNamespace: filter.metric_namespace
              }
            ])
          end
        end
      end
      
    end
  end
end
