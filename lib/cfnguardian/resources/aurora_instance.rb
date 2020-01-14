module CfnGuardian::Resource
  class AuroraInstance < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::AuroraInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighSpike'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AuroraInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 75
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AuroraInstanceAlarm.new(@resource)
      alarm.name = 'DatabaseConnections'
      alarm.metric_name = 'DatabaseConnections'
      alarm.statistic = 'Minimum'
      alarm.threshold = 45
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
    end
    
  end
end
