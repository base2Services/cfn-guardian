require 'aws-sdk-cloudwatch'
require 'time'

module CfnGuardian
  class CloudWatch
    include Logging
    
    def self.get_alarm_name(alarm)
      alarm_id = alarm.resource_name.nil? ? alarm.resource_id : alarm.resource_name
      return "guardian-#{alarm.group}-#{alarm_id}-#{alarm.name}"
    end
    
    def self.get_alarms(alarms)
      alarm_names = alarms.map {|alarm| self.get_alarm_name(alarm)}
      
      client = Aws::CloudWatch::Client.new()
      metric_alarms = []
      alarm_names.each_slice(100) do |batch|
        resp = client.describe_alarms({alarm_names: batch, max_records: 100})
        metric_alarms.push(*resp.metric_alarms)
      end
      
      return metric_alarms
    end
    
    def self.get_alarm_state(config_alarms: [], alarm_names: [], alarm_prefix: nil, state: nil)
      rows = []
      
      if config_alarms.any?
        alarm_names = config_alarms.map {|alarm| self.get_alarm_name(alarm)}
      end
      
      client = Aws::CloudWatch::Client.new()
      
      options = {max_records: 100}
      options[:state_value] = state if !state.nil?
      
      cw_alarms = []
      if !alarm_prefix.nil?
        options[:alarm_name_prefix] = alarm_prefix
        resp = client.describe_alarms(options)
        cw_alarms = resp.metric_alarms
      else
        alarm_names.each_slice(100) do |batch|
          options[:alarm_names] = batch
          resp = client.describe_alarms(options)
          cw_alarms.push(*resp.metric_alarms)
        end
      end
      
      return cw_alarms
    end
    
    def self.get_alarm_history(alarm_name,type)
      rows = []
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