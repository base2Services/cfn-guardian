module CfnGuardian::Resource
  class RDSInstance < Base
    
    def default_alarms 
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'FreeStorageSpaceCritical'
      alarm.metric_name = 'FreeStorageSpace'
      alarm.threshold = 50000000000
      alarm.evaluation_periods = 1
      alarm.comparison_operator = 'LessThanThreshold'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'FreeStorageSpaceTask'
      alarm.metric_name = 'FreeStorageSpace'
      alarm.threshold = 100000000000
      alarm.evaluation_periods = 1
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.alarm_action = 'Task'
      @alarms.push(alarm)
         
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighSpike'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 75
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'DatabaseConnections'
      alarm.metric_name = 'DatabaseConnections'
      alarm.statistic = 'Minimum'
      alarm.threshold = 45
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
    end
    
  end
end
