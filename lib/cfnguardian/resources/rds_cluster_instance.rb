module CfnGuardian::Resource
  class RDSClusterInstance < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::RDSClusterInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighSpike'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSClusterInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 75
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSClusterInstanceAlarm.new(@resource)
      alarm.name = 'DatabaseConnections'
      alarm.metric_name = 'DatabaseConnections'
      alarm.statistic = 'Minimum'
      alarm.threshold = 45
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
    end

    def default_event_subscriptions()
      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MasterPasswordReset'
      event_subscription.event_id = 'RDS-EVENT-0016'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MasterPasswordResetFailure'
      event_subscription.event_id = 'RDS-EVENT-0067'
      @event_subscriptions.push(event_subscription)
      
      event_subscription = CfnGuardian::Models::RDSClusterInstanceEventSubscription.new(@resource)
      event_subscription.name = 'AuroraStorageLow'
      event_subscription.event_id = 'RDS-EVENT-0227'
      @event_subscriptions.push(event_subscription)
    end
    
  end
end
