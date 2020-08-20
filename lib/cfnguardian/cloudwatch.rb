require 'aws-sdk-cloudwatch'
require 'time'

module CfnGuardian
  class CloudWatch
    include Logging
    
    def self.get_alarm_name(alarm)
      alarm_id = alarm.resource_name.nil? ? alarm.resource_id : alarm.resource_name
      return "guardian-#{alarm.group}-#{alarm_id}-#{alarm.name}"
    end
        
    def self.get_alarms_by_prefix(prefix:, state: nil, action_prefix: nil)
      client = Aws::CloudWatch::Client.new()
      options = {max_records: 100}
      options[:alarm_name_prefix] = prefix

      unless state.nil?
        options[:state_value] = state
      end

      unless action_prefix.nil?
        options[:action_prefix] = action_prefix
      end

      resp = client.describe_alarms(options)
      return resp.metric_alarms
    end

    def self.get_alarms_by_name(alarm_names:, state: nil, action_prefix: nil)
      client = Aws::CloudWatch::Client.new()
      options = {max_records: 100}

      unless state.nil?
        options[:state_value] = state
      end

      unless action_prefix.nil?
        options[:action_prefix] = "arn:aws:sns:#{Aws.config[:region]}:#{aws_account_id()}:#{action_prefix}"
      end

      metric_alarms = []
      alarm_names.each_slice(100) do |batch|
        options[:alarm_names] = batch
        resp = client.describe_alarms(options)
        metric_alarms.push(*resp.metric_alarms)
      end

      return metric_alarms
    end

    def self.filter_alarms(filters:, alarms:)
      return alarms unless filters.is_a?(Hash)
      filters = filters.slice('group', 'resource', 'alarm', 'stack-id')

      filtered_alarms = []
      alarms.each do |alarm|
        if filters.values.all? {|filter| alarm.alarm_name.include? (filter)}
          filtered_alarms << alarm
        end
      end

      return filtered_alarms
    end
    
    def self.get_alarm_history(alarm_name,type)
      client = Aws::CloudWatch::Client.new()
      
      logger.debug "Searching #{type} history for #{alarm_name}"
            
      resp = client.describe_alarm_history({
        alarm_name: alarm_name,
        history_item_type: type,
        start_date: (Time.now.utc.to_date - 7),
        end_date: (Time.now.utc.to_date + 1),
        max_records: 100
      })
      
      return resp.alarm_history_items
    end
    
    def self.get_alarm_names(action_prefix=nil,alarm_name_prefix='guardian')
      alarms = []
      client = Aws::CloudWatch::Client.new
      
      options = {
        alarm_types: ["CompositeAlarm","MetricAlarm"],
        alarm_name_prefix: alarm_name_prefix
      }
      
      unless action_prefix.nil?
        options[:action_prefix] = "arn:aws:sns:#{Aws.config[:region]}:#{aws_account_id()}:#{action_prefix}"
      end
      
      client.describe_alarms(options).each do |response|
        alarms.concat response.composite_alarms.map(&:alarm_name)
        alarms.concat response.metric_alarms.map(&:alarm_name)
      end
      
      return alarms
    end
    
    def self.disable_alarms(alarms)
      client = Aws::CloudWatch::Client.new
      alarms.each_slice(100) do |batch|
        client.disable_alarm_actions({alarm_names: batch})
      end
    end
    
    def self.enable_alarms(alarms)
      client = Aws::CloudWatch::Client.new
      alarms.each_slice(100) do |batch|
        client.enable_alarm_actions({alarm_names: batch})
      end
      
      alarms.each do |alarm|
        client.set_alarm_state({
          alarm_name: alarm,
          state_value: "OK",
          state_reason: "End of guardian maintenance peroid"
        })
      end
    end
    
    def self.aws_account_id()
      sts = Aws::STS::Client.new
      account = sts.get_caller_identity().account
      return account
    end
    
  end
end