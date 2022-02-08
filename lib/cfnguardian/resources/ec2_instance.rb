module CfnGuardian
  module Resource
    class Ec2Instance < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::Ec2InstanceAlarm.new(@resource)
        alarm.name = 'CPUUtilizationHigh'
        alarm.metric_name = 'CPUUtilization'
        alarm.statistic = 'Minimum'
        alarm.threshold = 90
        alarm.evaluation_periods = 10
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::Ec2InstanceAlarm.new(@resource)
        alarm.name = 'StatusCheckFailed'
        alarm.metric_name = 'StatusCheckFailed'
        alarm.threshold = 0
        alarm.evaluation_periods = 1
        alarm.comparison_operator = 'GreaterThanThreshold'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::Ec2InstanceAlarm.new(@resource)
        alarm.name = 'CPUCreditBalanceLow'
        alarm.metric_name = 'CPUCreditBalance'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'Minimum'
        alarm.threshold = 100
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.datapoints_to_alarm = 5
        @alarms.push(alarm)
      end
      
      def default_event_subscriptions()
        event_subscription = CfnGuardian::Models::Ec2InstanceEventSubscription.new(@resource)
        event_subscription.name = 'InstanceTerminated'
        event_subscription.detail_type = 'EC2 Instance State-change Notification'
        event_subscription.detail = {
          'instance-id' => [@resource['Id']],
          'state' => ['terminated']
        }
        @event_subscriptions.push(event_subscription)
      end

    end
  end
end
