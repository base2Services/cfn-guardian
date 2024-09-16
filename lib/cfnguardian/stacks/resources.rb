require 'cfndsl'
require 'digest/md5'
require 'cfnguardian/cloudwatch'

module CfnGuardian
  module Stacks
    class Resources
      include CfnDsl::CloudFormation
            
      def initialize(template)
        @template = template
      end
      
      def build_template(resources)
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
          when 'EventSubscription'
            add_event_subscription(resource)
          else
            puts "Warn: #{resource.type} is a unsuported resource type"
          end
        end
      end

      def add_alarm(alarm)
        actions = alarm.alarm_action.kind_of?(Array) ? alarm.alarm_action.map{|action| Ref(action)} : [Ref(alarm.alarm_action)]
        actions.concat alarm.maintenance_groups.map {|mg| Ref(mg)} if alarm.maintenance_groups.any?

        @template.declare do
          CloudWatch_Alarm("#{alarm.resource_hash}#{alarm.group}#{alarm.name.gsub(/[^0-9a-zA-Z]/i, '')}#{alarm.type}"[0..255]) do
            ActionsEnabled true
            AlarmDescription "Guardian alarm #{alarm.name} for the resource #{alarm.resource_id} in alarm group #{alarm.group}"
            AlarmName CfnGuardian::CloudWatch.get_alarm_name(alarm)
            ComparisonOperator alarm.comparison_operator
            Metrics alarm.metrics unless alarm.metrics.nil?
            Dimensions alarm.dimensions.map {|k,v| {Name: k, Value: v}} unless alarm.dimensions.nil?
            EvaluationPeriods alarm.evaluation_periods
            Statistic alarm.statistic if alarm.extended_statistic.nil? && alarm.metrics.nil?
            Period alarm.period if alarm.metrics.nil?
            Threshold alarm.threshold
            MetricName alarm.metric_name if alarm.metrics.nil?
            Namespace alarm.namespace if alarm.metrics.nil?
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
          Events_Rule("#{event.group}#{event.type}#{event.hash}"[0..255]) do
            State 'ENABLED'
            Description "Guardian scheduled #{event.group} #{event.type}"
            ScheduleExpression "cron(#{event.cron})"
            Targets([
              { 
                Arn: FnGetAtt(event.target, :Arn),
                Id: event.hash,
                Input: FnSub(event.payload)
              }
            ])
          end
        end
      end
      
      def add_composite_alarm(alarm)
        @template.declare do
          CloudWatch_CompositeAlarm(alarm.name.gsub(/[^0-9a-zA-Z]/i, '')) do
            
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
          Logs_MetricFilter("#{filter.name.gsub(/[^0-9a-zA-Z]/i, '')}#{filter.type}") do
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

      def add_event_subscription(subscription)
        event_pattern = {}
        event_pattern['detail-type'] = [subscription.detail_type] unless subscription.detail_type.empty?
        event_pattern['source'] = [subscription.source]
        event_pattern['resources'] = [subscription.resource_arn] unless subscription.resource_arn.empty?
        event_pattern['detail'] = subscription.detail unless subscription.detail.empty?

        @template.declare do
          Events_Rule("#{subscription.group}#{subscription.name}#{subscription.hash}"[0..255]) do
            State subscription.enabled ? 'ENABLED' : 'DISABLED'
            Description "Guardian event subscription #{subscription.group} #{subscription.name} for resource #{subscription.resource_id}"
            EventPattern FnSub(event_pattern.to_json)
            Targets [
              {
                Arn: Ref(subscription.topic),
                Id: "#{subscription.topic}Notifier"
              }
            ]
          end
        end
      end
      
    end
  end
end
