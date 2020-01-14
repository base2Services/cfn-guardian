module CfnGuardian::Resource
  class RedshiftCluster < Base
      
    def default_alarms    
      alarm = CfnGuardian::Models::RedshiftClusterAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighSpike'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RedshiftClusterAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 75
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RedshiftClusterAlarm.new(@resource)
      alarm.name = 'UnHealthyCluster'
      alarm.metric_name = 'HealthStatus'
      alarm.threshold = 0
      alarm.evaluation_periods = 10
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
    
  end
end
