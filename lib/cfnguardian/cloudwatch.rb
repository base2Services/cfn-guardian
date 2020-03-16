require 'aws-sdk-cloudwatch'
require 'time'

module CfnGuardian
  class CloudWatch
    include Logging
    
    def self.compare_alarms(alarms,topics)      
      alarm_names = alarms.map {|a| "#{a[:class]}-#{a[:resource]}-#{a[:name]}"}
      client = Aws::CloudWatch::Client.new()
      cw_alarms = []
      alarm_names.each_slice(100) do |batch|
        resp = client.describe_alarms({alarm_names: batch, max_records: 100})
        cw_alarms.push(*resp.metric_alarms)
      end
      
      alarms.each do |alarm|
        alarm_name = "#{alarm[:class]}-#{alarm[:resource]}-#{alarm[:name]}"
        metric_alarm = cw_alarms.find {|ma| ma.alarm_name == alarm_name}
        
        if metric_alarm
          ma_hash = metric_alarm.to_h
          alarm.each do |k,v|
            if k == :dimensions
              alarm[k] = [v,ma_hash[k].map {|a| {a[:name].to_sym => a[:value]}}.inject(:merge)]
            elsif k == :threshold
              alarm[k] = [v.to_f,ma_hash[k]]
            elsif ![:class,:name].include? k
              alarm[k] = [v,ma_hash[k]]
            end
          end
        else
          alarm.each {|k,v| alarm[k] = [v,"Not Found"] unless [:class,:name].include?(k)}
        end
      end
    end
    
    def self.get_alarm_state(alarm_names: [], alarm_prefix: nil, state: nil)
      rows = []
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
      
      cw_alarms.each do |ma|      
        if ma.state_value == 'ALARM'
          state_value = ma.state_value.to_s.red
        elsif ma.state_value == 'INSUFFICIENT_DATA'
          state_value = ma.state_value.to_s.yellow
        else
          state_value = ma.state_value.to_s.green
        end
        
        rows << [
          ma.alarm_name, 
          state_value, 
          ma.state_updated_timestamp.localtime,
          ma.actions_enabled ? 'ENABLED'.green : 'DISABLED'.red
        ]
      end
      # sort by state_value
      return rows.sort_by {|r| r[3]}
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
      
      
      resp.alarm_history_items.each do |history|
        data = JSON.load(history.history_data)
        
        case type
        when "StateUpdate" 
          rows << [
            history.timestamp.localtime, 
            history.history_summary, 
            data['newState']['stateReason']
          ]
        when "ConfigurationUpdate"
          updated = []
          if data['type'] == 'Update'
            data['originalUpdatedFields'].each do |k,v|
              unless k == 'alarmConfigurationUpdatedTimestamp'
                updated << "#{k}: #{v} -> #{data['updatedAlarm'][k]}"
              end
            end
          end
          rows << [
            history.timestamp.localtime, 
            data['type'],
            updated.join("\n")
          ]
        end
      end
      
      return rows
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