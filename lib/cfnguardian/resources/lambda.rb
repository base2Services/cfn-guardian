module CfnGuardian::Resource
  class Lambda < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'LambdaErrors'
      alarm.metric_name = 'Errors'
      alarm.threshold = 0.5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'Throttles'
      alarm.metric_name = 'Throttles'
      alarm.threshold = 0.5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'DeadLetterErrors'
      alarm.metric_name = 'DeadLetterErrors'
      alarm.threshold = 0.5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'IteratorAge'
      alarm.metric_name = 'IteratorAge'
      alarm.threshold = 600000
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'Duration'
      alarm.metric_name = 'Duration'
      alarm.statistic = 'Average'
      alarm.threshold = 30
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
    
  end
end
