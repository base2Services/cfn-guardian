module CfnGuardian::Resource
  class KafkaCluster < Base

    def initialize(resource, override_group = nil)
      super(resource, override_group)
      @brokers_list = resource['Brokers']
    end

    def default_alarms
      @brokers_list.each do |broker|
        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-CPUUserCritical"
        alarm.metric_name = 'CpuUser'
        alarm.threshold = 80
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-CPUUserWarning"
        alarm.metric_name = 'CpuUser'
        alarm.threshold = 50
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-KafkaDataLogsDiskUsedCritical"
        alarm.metric_name = 'KafkaDataLogsDiskUsed'
        alarm.threshold = 85
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-KafkaDataLogsDiskUsedWarning"
        alarm.metric_name = 'KafkaDataLogsDiskUsed'
        alarm.threshold = 70
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-BurstBalance"
        alarm.metric_name = 'BurstBalance'
        alarm.threshold = 1
        alarm.comparison_operator = 'LessThanThreshold'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-MemoryFreeCritical"
        alarm.metric_name = 'MemoryFree'
        alarm.threshold = 10
        alarm.comparison_operator = 'LessThanThreshold'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-MemoryFreeWarning"
        alarm.metric_name = 'MemoryFree'
        alarm.threshold = 50
        alarm.alarm_action = 'Warning'
        alarm.comparison_operator = 'LessThanThreshold'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-NetworkRxErrorsCritical"
        alarm.metric_name = 'NetworkRxErrors'
        alarm.threshold = 10
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::KafkaClusterAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-NetworkRxErrorsWarning"
        alarm.metric_name = 'NetworkRxErrors'
        alarm.threshold = 5
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)
      end
    end
  end
end
