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
        use_anomaly_detection = alarm.anomaly_detection == true

        rows = [
          ['ResourceId', alarm.resource_id],
          ['ResourceHash', alarm.resource_hash],
          ['ResourceName', alarm.resource_name],
          ['Enabled', alarm.enabled],
          ['MetricName', alarm.metric_name],
          ['Dimensions', alarm.dimensions],
          # An anomaly detection alarm uses ThresholdMetricId/StandardDeviation instead of a static Threshold.
          ['Threshold', use_anomaly_detection ? nil : alarm.threshold],
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
          ['OkActionDisabled', alarm.ok_action_disabled],
          ['TreatMissingData', alarm.treat_missing_data],
          ['AnomalyDetection', use_anomaly_detection ? alarm.anomaly_detection : nil],
          ['StandardDeviation', use_anomaly_detection ? (alarm.standard_deviation || 2) : nil]
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
        use_anomaly_detection = alarm.anomaly_detection == true
        deployed_anomaly_detection = anomaly_detection_deployed?(metric_alarm)

        # A real deployed anomaly detection alarm has no top-level MetricName/Statistic/
        # Period/Unit/Dimensions - CloudWatch only populates those nested inside the raw
        # metric's MetricStat (see #deployed_metric_stat). Fall back to the top-level fields
        # when the deployed alarm isn't a metric-math alarm at all (e.g. local config wants
        # anomaly detection but the deployed alarm is still a plain static alarm).
        metric_stat = deployed_metric_stat(metric_alarm)
        if metric_stat
          deployed_metric_name = metric_stat.metric.metric_name
          deployed_dimensions = (metric_stat.metric.dimensions || []).map {|dim| {dim.name.to_sym => dim.value}}.inject(:merge)
          deployed_period = metric_stat.period
          deployed_statistic = metric_stat.stat
          deployed_unit = metric_stat.unit
        else
          deployed_metric_name = metric_alarm.metric_name
          deployed_dimensions = (metric_alarm.dimensions || []).map {|dim| {dim.name.to_sym => dim.value}}.inject(:merge)
          deployed_period = metric_alarm.period
          deployed_statistic = metric_alarm.statistic
          deployed_unit = metric_alarm.unit
        end

        # An anomaly detection alarm's MetricStat.Stat holds whichever of Statistic/
        # ExtendedStatistic cfn-guardian generated (see stacks/resources.rb#add_alarm), so
        # compare that combined value here and suppress the separate ExtendedStatistic row
        # below - the same way Threshold is already suppressed for anomaly alarms.
        local_statistic = use_anomaly_detection ? (alarm.extended_statistic || alarm.statistic) : alarm.statistic

        rows = [
          ['ResourceId', alarm.resource_id, alarm.resource_id],
          ['ResourceHash', alarm.resource_hash, alarm.resource_hash],
          ['ResourceName', alarm.resource_name, alarm.resource_name],
          ['Enabled', alarm.enabled, true],
          ['MetricName', alarm.metric_name, deployed_metric_name],
          ['Dimensions', alarm.dimensions, deployed_dimensions],
          # A correctly deployed anomaly detection alarm has no static Threshold (it uses
          # ThresholdMetricId/Metrics instead), so comparing Threshold here would always show
          # as different. Compare AnomalyDetection/StandardDeviation below instead.
          ['Threshold', use_anomaly_detection ? nil : alarm.threshold.to_f, use_anomaly_detection ? nil : metric_alarm.threshold],
          ['Period', alarm.period, deployed_period],
          ['EvaluationPeriods', alarm.evaluation_periods, metric_alarm.evaluation_periods],
          ['ComparisonOperator', alarm.comparison_operator, metric_alarm.comparison_operator],
          ['Statistic', local_statistic, deployed_statistic],
          ['ActionsEnabled', alarm.actions_enabled, metric_alarm.actions_enabled],
          ['DatapointsToAlarm', alarm.datapoints_to_alarm, metric_alarm.datapoints_to_alarm],
          ['ExtendedStatistic', use_anomaly_detection ? nil : alarm.extended_statistic, use_anomaly_detection ? nil : metric_alarm.extended_statistic],
          ['EvaluateLowSampleCountPercentile', alarm.evaluate_low_sample_count_percentile, metric_alarm.evaluate_low_sample_count_percentile],
          ['Unit', alarm.unit, deployed_unit],
          ['TreatMissingData', alarm.treat_missing_data, metric_alarm.treat_missing_data],
          ['AlarmAction', alarm.alarm_action, alarm.alarm_action],
          ['OkActionDisabled', alarm.ok_action_disabled]
        ]

        if use_anomaly_detection || deployed_anomaly_detection
          rows << ['AnomalyDetection', use_anomaly_detection, deployed_anomaly_detection]
          rows << ['StandardDeviation', use_anomaly_detection ? (alarm.standard_deviation || 2).to_f : nil, deployed_standard_deviation(metric_alarm)]
        end

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

    # An anomaly detection alarm is identified on the deployed side by having a
    # ThresholdMetricId set (it references the ANOMALY_DETECTION_BAND expression in Metrics).
    def anomaly_detection_deployed?(metric_alarm)
      !metric_alarm.threshold_metric_id.nil? && !metric_alarm.threshold_metric_id.to_s.empty?
    end

    # For an anomaly detection alarm, CloudWatch does not populate the top-level MetricName/
    # Namespace/Statistic/Period/Unit/Dimensions fields on describe_alarms - those live nested
    # inside the raw metric's MetricStat, referenced by the Metrics array entry cfn-guardian
    # generates with Id 'm1' (see stacks/resources.rb#add_alarm). Returns nil when the deployed
    # alarm has no such entry (e.g. it's a plain static alarm, not managed via Metrics/MetricStat).
    def deployed_metric_stat(metric_alarm)
      raw_metric = (metric_alarm.metrics || []).find {|m| m.id == 'm1' && !m.metric_stat.nil?}
      raw_metric.nil? ? nil : raw_metric.metric_stat
    end

    # Extracts the StandardDeviation from the deployed ANOMALY_DETECTION_BAND(m1, <stddev>)
    # expression referenced by ThresholdMetricId. This is approximate: it assumes the band
    # expression is in the same shape cfn-guardian generates, and returns nil if it can't be
    # found or parsed (e.g. an anomaly alarm not managed by cfn-guardian). The number pattern
    # also matches scientific notation (e.g. "1.0e-06"), since add_alarm embeds Ruby's
    # Float#to_s form of StandardDeviation and to_s switches to that notation for very
    # small (or very large) finite values.
    def deployed_standard_deviation(metric_alarm)
      return nil unless anomaly_detection_deployed?(metric_alarm)

      band_metric = (metric_alarm.metrics || []).find {|m| m.id == metric_alarm.threshold_metric_id}
      return nil if band_metric.nil? || band_metric.expression.nil?

      match = band_metric.expression.match(/ANOMALY_DETECTION_BAND\([^,]+,\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*\)/)
      match.nil? ? nil : match[1].to_f
    end

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