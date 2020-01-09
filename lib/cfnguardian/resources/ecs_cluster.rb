module CfnGuardian::Resource
  class EcsCluster < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::EcsClusterAlarm.new(@resource)
      alarm.name = 'CPUUtilizationWarning'
      alarm.metric_name = 'CPUUtilization'
      alarm.statistic = 'Minimum'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::EcsClusterAlarm.new(@resource)
      alarm.name = 'MemoryUtilizationWarning'
      alarm.metric_name = 'MemoryUtilization'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::EcsClusterAlarm.new(@resource)
      alarm.name = 'MemoryUtilizationCritical'
      alarm.metric_name = 'MemoryUtilization'
      alarm.alarm_action = 'Critical'
      alarm.threshold = 90
      @alarms.push(alarm)
    end
    
  end
end
