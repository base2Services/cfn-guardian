module CfnGuardian::Resource
  class Lambda < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'LambdaErrors'
      alarm.metric_name = 'Errors'
      alarm.threshold = 0.5
      alarm.evaluation_periods = 1
      alarm.datapoints_to_alarm = 1
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'Throttles'
      alarm.metric_name = 'Throttles'
      alarm.threshold = 0.5
      alarm.evaluation_periods = 1
      alarm.datapoints_to_alarm = 1
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'DeadLetterErrors'
      alarm.metric_name = 'DeadLetterErrors'
      alarm.threshold = 0.5
      alarm.evaluation_periods = 1
      alarm.datapoints_to_alarm = 1
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.enabled = false
      alarm.name = 'IteratorAge'
      alarm.metric_name = 'IteratorAge'
      alarm.threshold = 600000
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.enabled = false
      alarm.name = 'Duration'
      alarm.metric_name = 'Duration'
      alarm.statistic = 'Average'
      alarm.threshold = 30
      @alarms.push(alarm)
    end
    
  end
end
