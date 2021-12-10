module CfnGuardian
  module Resource
    class ECSService < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'UnhealthyTaskCritical'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        alarm.statistic = 'SampleCount'
        alarm.threshold = 0
        alarm.evaluation_periods = 10
        alarm.datapoints_to_alarm = 8
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'UnhealthyTaskWarning'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        alarm.statistic = 'SampleCount'
        alarm.threshold = 1
        alarm.evaluation_periods = 10
        alarm.datapoints_to_alarm = 8
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)
      end
      
    end
  end
end
