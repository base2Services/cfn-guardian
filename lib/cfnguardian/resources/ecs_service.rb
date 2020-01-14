module CfnGuardian
  module Resource
    class EcsService < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::EcsServiceAlarm.new(@resource)
        alarm.name = 'UnhealthyTaskCritical'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        alarm.statistic = 'SampleCount'
        alarm.threshold = 15
        alarm.evaluation_periods = 10
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 8
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::EcsServiceAlarm.new(@resource)
        alarm.name = 'UnhealthyTaskWarning'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        alarm.statistic = 'SampleCount'
        alarm.threshold = 15
        alarm.evaluation_periods = 10
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 8
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)
      end
      
    end
  end
end
