module CfnGuardian::Resource
  class AmazonMQ < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::AmazonMQAlarm.new(@resource)
      alarm.name = 'CpuCreditBalanceCritical'
      alarm.metric_name = 'CpuCreditBalance'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 15
      alarm.evaluation_periods = 1
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQAlarm.new(@resource)
      alarm.name = 'CpuCreditBalanceCritical'
      alarm.metric_name = 'CpuCreditBalance'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 30
      alarm.evaluation_periods = 1
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQAlarm.new(@resource)
      alarm.name = 'CpuUtilizationCritical'
      alarm.metric_name = 'CpuUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 3
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AmazonMQAlarm.new(@resource)
      alarm.name = 'CpuUtilizationWarning'
      alarm.metric_name = 'CpuUtilization'
      alarm.threshold = 80
      alarm.evaluation_periods = 3
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
    end
    
  end
end
