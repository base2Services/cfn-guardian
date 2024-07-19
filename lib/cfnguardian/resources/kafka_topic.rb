module CfnGuardian::Resource
  class KafkaTopic < Base

    def initialize(resource, override_group = nil)
      super(resource, override_group)
      @brokers_list = resource['Brokers']
    end

    def default_alarms
      @brokers_list.each do |broker|  
        alarm = CfnGuardian::Models::KafkaTopicAlarm.new(@resource,broker)
        alarm.name = "Broker#{broker}-MessagesInPerSec"
        alarm.metric_name = 'MessagesInPerSec'
        alarm.threshold = 5
        alarm.comparison_operator = 'LessThanThreshold'
        @alarms.push(alarm)
      end
    end
  end
end
