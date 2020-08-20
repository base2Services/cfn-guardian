require 'cfnguardian/cloudwatch'
require 'cfnguardian/string'
require 'time'

module CfnGuardian
  class DisplayFormatter
    
    def initialize(alarms=[])
      @alarms = alarms
    end  
    
    def alarms()
      resp = []
      
      @alarms.each do |alarm|
        alarm_name = CfnGuardian::CloudWatch.get_alarm_name(alarm)
        rows = [
          ['ResourceId', alarm.resource_id],
          ['ResourceHash', alarm.resource_hash],
          ['ResourceName', alarm.resource_name],
          ['Enabled', alarm.enabled],
          ['MetricName', alarm.metric_name],
          ['Dimensions', alarm.dimensions],
          ['Threshold', alarm.threshold],
          ['Period', alarm.period],
          ['EvaluationPeriods', alarm.evaluation_periods],
          ['ComparisonOperator', alarm.comparison_operator],
          ['Statistic', alarm.statistic],
          ['ActionsEnabled', alarm.actions_enabled],
          ['DatapointsToAlarm', alarm.datapoints_to_alarm],
          ['ExtendedStatistic', alarm.extended_statistic],
          ['EvaluateLowSampleCountPercentile', alarm.evaluate_low_sample_count_percentile],
          ['Unit', alarm.unit],
          ['AlarmAction', alarm.alarm_action],
          ['TreatMissingData', alarm.treat_missing_data]
        ]
        
        rows.select! {|row| !row[1].nil?}
        
        resp << {
          title: "#{alarm.group}::#{alarm.name}".green + "\n" + alarm_name.green,
          rows: rows
        }
      end
      
      return resp
    end
    
    def compare_alarms(metric_alarms)      
      resp = []
      
      @alarms.each do |alarm|
        alarm_name = CfnGuardian::CloudWatch.get_alarm_name(alarm)
        metric_alarm = metric_alarms.find {|ma| ma.alarm_name.include? alarm_name}
        dimensions = metric_alarm.dimensions.map {|dim| {dim.name.to_sym => dim.value}}.inject(:merge)
        
        rows = [
          ['ResourceId', alarm.resource_id, alarm.resource_id],
          ['ResourceHash', alarm.resource_hash, alarm.resource_hash],
          ['ResourceName', alarm.resource_name, alarm.resource_name],
          ['Enabled', alarm.enabled, true],
          ['MetricName', alarm.metric_name, metric_alarm.metric_name],
          ['Dimensions', alarm.dimensions, dimensions],
          ['Threshold', alarm.threshold.to_f, metric_alarm.threshold],
          ['Period', alarm.period, metric_alarm.period],
          ['EvaluationPeriods', alarm.evaluation_periods, metric_alarm.evaluation_periods],
          ['ComparisonOperator', alarm.comparison_operator, metric_alarm.comparison_operator],
          ['Statistic', alarm.statistic, metric_alarm.statistic],
          ['ActionsEnabled', alarm.actions_enabled, metric_alarm.actions_enabled],
          ['DatapointsToAlarm', alarm.datapoints_to_alarm, metric_alarm.datapoints_to_alarm],
          ['ExtendedStatistic', alarm.extended_statistic, metric_alarm.extended_statistic],
          ['EvaluateLowSampleCountPercentile', alarm.evaluate_low_sample_count_percentile, metric_alarm.evaluate_low_sample_count_percentile],
          ['Unit', alarm.unit, metric_alarm.unit],
          ['TreatMissingData', alarm.treat_missing_data, metric_alarm.treat_missing_data],
          ['AlarmAction', alarm.alarm_action, alarm.alarm_action]
        ]
        
        rows.select! {|row| !row[1].nil?}.each {|row| colour_compare_row(row)}
        
        if has_config_difference?(rows)
          resp << {
            title: "#{alarm.group}::#{alarm.name}".green + "\n" + alarm_name.green,
            rows: rows
          }
        end
      end
      
      return resp
    end
    
    def alarm_state(metric_alarms)
      rows = []
      
      metric_alarms.each do |ma|      
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
    
    def alarm_history(history,type)
      rows = []
      line_width = 100
      
      history.each do |item|
        data = JSON.load(item.history_data)
        
        case type
        when "StateUpdate" 
          rows << [
            item.timestamp.localtime, 
            item.history_summary,
            data['newState']['stateReason'].word_wrap
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
            item.timestamp.localtime, 
            data['type'],
            updated.join("\n").word_wrap
          ]
        end
      end
      
      return rows
    end
    
    private
    
    def has_config_difference?(rows)
      rows.each do |row| 
        unless row[1].eql?(row[2])
          return true
        end
      end
      return false 
    end
    
    def colour_compare_row(row)
      return row[1].eql?(row[2]) ? row.map! {|r| r.to_s.green} : row.map! {|r| r.to_s.red}
    end
  end
end