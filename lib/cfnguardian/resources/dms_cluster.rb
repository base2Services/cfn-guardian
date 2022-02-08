module CfnGuardian::Resource
  class DMSCluster < Base
    
    def default_alarms 
      alarm = CfnGuardian::Models::DMSClusterAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighSpike'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 90
      alarm.statistic = 'Minimum'
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DMSClusterAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 2
      alarm.statistic = 'Maximum'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DMSClusterAlarm.new(@resource)
      alarm.name = 'FreeStorageSpaceCrit'
      alarm.metric_name = 'FreeStorageSpace'
      alarm.statistic = 'Minimum'
      alarm.threshold = 10000000000
      alarm.evaluation_periods = 1
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DMSClusterAlarm.new(@resource)
      alarm.name = 'FreeStorageSpaceWarn'
      alarm.metric_name = 'FreeStorageSpace'
      alarm.statistic = 'Minimum'
      alarm.threshold = 20000000000
      alarm.evaluation_periods = 1
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
    end
  end
end
