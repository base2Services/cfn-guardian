module CfnGuardian::Resource
  class AmazonMQBroker < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::AmazonMQBrokerAlarm.new(@resource)
      alarm.name = 'CpuCreditBalanceCritical'
      alarm.metric_name = 'CpuCreditBalance'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 15
      alarm.period = 300
      alarm.datapoints_to_alarm = 2
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQBrokerAlarm.new(@resource)
      alarm.name = 'CpuCreditBalanceWarning'
      alarm.metric_name = 'CpuCreditBalance'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 30
      alarm.period = 300
      alarm.datapoints_to_alarm = 2
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQBrokerAlarm.new(@resource)
      alarm.name = 'CpuUtilizationCritical'
      alarm.metric_name = 'CpuUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 3
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQBrokerAlarm.new(@resource)
      alarm.name = 'CpuUtilizationWarning'
      alarm.metric_name = 'CpuUtilization'
      alarm.threshold = 80
      alarm.evaluation_periods = 3
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQBrokerAlarm.new(@resource)
      alarm.name = 'StorePercentUsageCritical'
      alarm.metric_name = 'StorePercentUsage'
      alarm.threshold = 90
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQBrokerAlarm.new(@resource)
      alarm.name = 'StorePercentUsageTask'
      alarm.metric_name = 'StorePercentUsage'
      alarm.threshold = 75
      alarm.evaluation_periods = 10
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Task'
      @alarms.push(alarm)
    end
    
  end
end
