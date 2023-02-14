module CfnGuardian::Resource
  class NetworkTargetGroup < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::NetworkTargetGroupAlarm.new(@resource)
      alarm.name = 'HealthyHosts'
      alarm.metric_name = 'HealthyHostCount'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 2
      alarm.evaluation_periods = 1
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::NetworkTargetGroupAlarm.new(@resource)
      alarm.name = 'UnHealthyHosts'
      alarm.metric_name = 'UnHealthyHostCount'
      alarm.threshold = 0
      alarm.evaluation_periods = 10
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::NetworkTargetGroupAlarm.new(@resource)
      alarm.name = 'TargetResponseTime'
      alarm.metric_name = 'TargetResponseTime'
      alarm.threshold = 5
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      alarm.enabled = false
      @alarms.push(alarm)
    end
    
  end
end
