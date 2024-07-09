module CfnGuardian::Resource
  class KafkaTopic < Base

    def default_alarms    
      alarm = CfnGuardian::Models::KafkaTopicAlarm.new(@resource)
      alarm.name = 'MessagesInPerSec'
      alarm.metric_name = 'MessagesInPerSec'
      alarm.threshold = 5
      alarm.comparison_operator = 'LessThanThreshold'
      @alarms.push(alarm)
    end
  end
end
