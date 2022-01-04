module CfnGuardian
  module Resource
    class ECSService < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'UnhealthyTaskCritical'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'SampleCount'
        alarm.threshold = 0
        alarm.evaluation_periods = 10
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 8
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'UnhealthyTaskWarning'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'SampleCount'
        alarm.threshold = 1
        alarm.evaluation_periods = 10
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 8
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'MemoryUtilizationCritical'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'GreaterThanOrEqualToThreshold'
        alarm.statistic = 'Average'
        alarm.threshold = 90
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'breaching'
        alarm.alarm_action = 'Critical'
        alarm.datapoints_to_alarm = 4
        alarm.treat_missing_data = 'notBreaching'
        alarm.enabled = false
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'MemoryUtilizationWarning'
        alarm.metric_name = 'MemoryUtilization'
        alarm.comparison_operator = 'GreaterThanOrEqualToThreshold'
        alarm.statistic = 'Average'
        alarm.threshold = 80
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 4
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        alarm.enabled = false
        @alarms.push(alarm)   

        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'CPUUtilizationCritical'
        alarm.metric_name = 'CPUUtilization'
        alarm.comparison_operator = 'GreaterThanOrEqualToThreshold'
        alarm.statistic = 'Average'
        alarm.threshold = 90
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'breaching'
        alarm.alarm_action = 'Critical'
        alarm.datapoints_to_alarm = 4
        alarm.treat_missing_data = 'notBreaching'
        alarm.enabled = false
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ECSServiceAlarm.new(@resource)
        alarm.name = 'CPUUtilizationWarning'
        alarm.metric_name = 'CPUUtilization'
        alarm.comparison_operator = 'GreaterThanOrEqualToThreshold'
        alarm.statistic = 'Average'
        alarm.threshold = 80
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 4
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        alarm.enabled = false
        @alarms.push(alarm)      
      end
    end
  end
end
