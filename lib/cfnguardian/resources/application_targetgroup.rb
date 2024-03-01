module CfnGuardian::Resource
  class ApplicationTargetGroup < Base
        
    def default_alarms    
      alarm = CfnGuardian::Models::ApplicationTargetGroupAlarm.new(@resource)
      alarm.name = 'HealthyHosts'
      alarm.metric_name = 'HealthyHostCount'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 2
      alarm.evaluation_periods = 1
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ApplicationTargetGroupAlarm.new(@resource)
      alarm.name = 'UnHealthyHosts'
      alarm.metric_name = 'UnHealthyHostCount'
      alarm.threshold = 0
      alarm.evaluation_periods = 10
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ApplicationTargetGroupAlarm.new(@resource)
      alarm.enabled = false
      alarm.name = 'TargetResponseTime'
      alarm.metric_name = 'TargetResponseTime'
      alarm.extended_statistic = 'p95'
      alarm.threshold = 5
      alarm.evaluation_periods = 5
      @alarms.push(alarm)
    end
    
  end
end
