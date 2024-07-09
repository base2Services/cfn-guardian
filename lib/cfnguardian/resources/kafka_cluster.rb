module CfnGuardian::Resource
  class KafkaCluster < Base

    def default_alarms    
      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'CPUUserCritical'
      alarm.metric_name = 'CPUUser'
      alarm.threshold = 80
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'CPUUserWarning'
      alarm.metric_name = 'CPUUser'
      alarm.threshold = 50
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'KafkaDataLogsDiskUsedCritical'
      alarm.metric_name = 'KafkaDataLogsDiskUsed'
      alarm.threshold = 85
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'KafkaDataLogsDiskUsedWarning'
      alarm.metric_name = 'KafkaDataLogsDiskUsed'
      alarm.threshold = 70
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'BurstBalance'
      alarm.metric_name = 'BurstBalance'
      alarm.threshold = 1
      alarm.comparison_operator = 'LessThanThreshold'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'MemoryFreeCritical'
      alarm.metric_name = 'MemoryFree'
      alarm.threshold = 10
      alarm.comparison_operator = 'LessThanThreshold'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'MemoryFreeWarning'
      alarm.metric_name = 'MemoryFree'
      alarm.threshold = 50
      alarm.alarm_action = 'Warning'
      alarm.comparison_operator = 'LessThanThreshold'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'NetworkRxErrorsCritical'
      alarm.metric_name = 'NetworkRxErrors'
      alarm.threshold = 10
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource)
      alarm.name = 'NetworkRxErrorsWarning'
      alarm.metric_name = 'NetworkRxErrors'
      alarm.threshold = 5
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
    end
    
  end
end
