module CfnGuardian::Resource
  class SQSQueue < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::SQSQueueAlarm.new(@resource)
      alarm.name = 'ApproximateAgeOfOldestMessage'
      alarm.metric_name = 'ApproximateAgeOfOldestMessage'
      alarm.threshold = 0.5
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::SQSQueueAlarm.new(@resource)
      alarm.name = 'ApproximateNumberOfMessagesVisible'
      alarm.metric_name = 'ApproximateNumberOfMessagesVisible'
      alarm.threshold = 0.5
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
    
  end
end
