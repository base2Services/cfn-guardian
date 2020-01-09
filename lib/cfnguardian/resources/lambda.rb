module CfnGuardian::Resource
  class Lambda < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::LambdaAlarm.new(@resource)
      alarm.name = 'LambdaErrors'
      alarm.metric_name = 'Errors'
      alarm.threshold = 0.5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
    
  end
end
