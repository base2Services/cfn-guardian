module CfnGuardian::Resource
  class AutoScalingGroup < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::AutoScalingGroupAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.statistic = 'Minimum'
      alarm.threshold = 90
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::AutoScalingGroupAlarm.new(@resource)
      alarm.name = 'StatusCheckFailed'
      alarm.metric_name = 'StatusCheckFailed'
      alarm.threshold = 0
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
    end
    
  end
end
