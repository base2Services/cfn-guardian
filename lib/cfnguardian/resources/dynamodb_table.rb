module CfnGuardian::Resource
  class DynamoDBTable < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::DynamoDBTableAlarm.new(@resource)
      alarm.name = 'DynamoDBReadUsage'
      alarm.metric_name = 'ConsumedReadCapacityUnits'
      alarm.statistic = 'Sum'
      alarm.threshold = 80
      alarm.evaluation_periods = 2
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DynamoDBTableAlarm.new(@resource)
      alarm.name = 'DynamoDBWriteUsage'
      alarm.metric_name = 'ConsumedWriteCapacityUnits'
      alarm.statistic = 'Sum'
      alarm.threshold = 80
      alarm.evaluation_periods = 2
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DynamoDBTableAlarm.new(@resource)
      alarm.name = 'DynamoDBReadThrottleEvents'
      alarm.metric_name = 'ReadThrottleEvents'
      alarm.comparison_operator = 'GreaterThanOrEqualToThreshold'
      alarm.statistic = 'Sum'
      alarm.threshold = 1
      alarm.evaluation_periods = 2
      alarm.alarm_action = 'Warning'
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DynamoDBTableAlarm.new(@resource)
      alarm.name = 'DynamoDBWriteThrottleEvents'
      alarm.metric_name = 'WriteThrottleEvents'
      alarm.comparison_operator = 'GreaterThanOrEqualToThreshold'
      alarm.statistic = 'Sum'
      alarm.threshold = 1
      alarm.evaluation_periods = 2
      alarm.alarm_action = 'Warning'
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
    
  end
end

