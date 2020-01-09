module CfnGuardian::Resource
  class ElasticLoadBalancer < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::ElasticLoadBalancerAlarm.new(@resource)
      alarm.name = 'HealthyHosts'
      alarm.metric_name = 'HealthyHostCount'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 2
      alarm.evaluation_periods = 1
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ElasticLoadBalancerAlarm.new(@resource)
      alarm.name = 'UnHealthyHosts'
      alarm.metric_name = 'UnHealthyHostCount'
      alarm.threshold = 0
      alarm.evaluation_periods = 10
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
    end
    
  end
end
