require 'spec_helper'
require 'term/ansicolor'
require 'aws-sdk-cloudwatch'
require 'cfnguardian/log'
require 'cfnguardian/string'
require 'cfnguardian/models/alarm'
require 'cfnguardian/display_formatter'

RSpec.describe CfnGuardian::DisplayFormatter do
  # Builds a local alarm config. Fields not relevant to the anomaly-detection
  # comparison being tested (Statistic, ExtendedStatistic, etc.) are pinned to nil
  # on both the local alarm and the fake deployed alarm below so they never
  # contribute an unrelated diff - comparing those fields for an anomaly alarm is
  # a separate, pre-existing approximation that this fix does not attempt to solve.
  def build_alarm(anomaly_detection: false, standard_deviation: nil, threshold: 80)
    alarm = CfnGuardian::Models::BaseAlarm.new({ 'Id' => 'i-0123456789abcdef0' })
    alarm.group = 'Ec2Instance'
    alarm.name = 'CPUUtilizationHigh'
    alarm.metric_name = 'CPUUtilization'
    alarm.namespace = 'AWS/EC2'
    alarm.dimensions = { InstanceId: 'i-0123456789abcdef0' }
    alarm.threshold = threshold
    alarm.comparison_operator = anomaly_detection ? 'GreaterThanUpperThreshold' : 'GreaterThanThreshold'
    alarm.statistic = nil
    alarm.anomaly_detection = anomaly_detection
    alarm.standard_deviation = standard_deviation
    alarm
  end

  def build_metric_alarm(alarm:, threshold_metric_id: nil, band_expression: nil, threshold: nil)
    metrics = nil
    if threshold_metric_id
      metrics = [
        Aws::CloudWatch::Types::MetricDataQuery.new(
          id: 'm1',
          metric_stat: Aws::CloudWatch::Types::MetricStat.new(
            metric: Aws::CloudWatch::Types::Metric.new(namespace: alarm.namespace, metric_name: alarm.metric_name),
            period: alarm.period,
            stat: 'Maximum'
          ),
          return_data: true
        ),
        Aws::CloudWatch::Types::MetricDataQuery.new(
          id: threshold_metric_id,
          expression: band_expression,
          return_data: true
        )
      ]
    end

    Aws::CloudWatch::Types::MetricAlarm.new(
      alarm_name: CfnGuardian::CloudWatch.get_alarm_name(alarm),
      metric_name: alarm.metric_name,
      namespace: alarm.namespace,
      dimensions: alarm.dimensions.map {|k, v| Aws::CloudWatch::Types::Dimension.new(name: k.to_s, value: v)},
      threshold: threshold,
      period: alarm.period,
      evaluation_periods: alarm.evaluation_periods,
      comparison_operator: alarm.comparison_operator,
      statistic: nil,
      actions_enabled: alarm.actions_enabled,
      datapoints_to_alarm: alarm.datapoints_to_alarm,
      extended_statistic: nil,
      evaluate_low_sample_count_percentile: alarm.evaluate_low_sample_count_percentile,
      unit: alarm.unit,
      treat_missing_data: alarm.treat_missing_data,
      threshold_metric_id: threshold_metric_id,
      metrics: metrics
    )
  end

  def strip_ansi(str)
    str.to_s.gsub(/\e\[\d+m/, '')
  end

  # Finds a compare_alarms row by name once colour_compare_row has wrapped every
  # cell in ANSI colour codes.
  def row_by_name(rows, name)
    rows.find {|row| strip_ansi(row[0]) == name}
  end

  def row_matches?(row)
    strip_ansi(row[1]) == strip_ansi(row[2])
  end

  describe '#alarms' do
    it 'shows the static Threshold and omits anomaly fields for a standard alarm' do
      alarm = build_alarm(anomaly_detection: false)
      formatter = CfnGuardian::DisplayFormatter.new([alarm])

      rows = formatter.alarms.first[:rows]
      row_names = rows.map(&:first)

      expect(row_names).to include('Threshold')
      expect(row_names).not_to include('AnomalyDetection')
      expect(row_names).not_to include('StandardDeviation')
    end

    it 'omits the misleading static Threshold and shows anomaly fields for an anomaly alarm' do
      alarm = build_alarm(anomaly_detection: true, standard_deviation: 3)
      formatter = CfnGuardian::DisplayFormatter.new([alarm])

      rows = formatter.alarms.first[:rows]
      row_hash = rows.to_h

      expect(row_hash).not_to have_key('Threshold')
      expect(row_hash['AnomalyDetection']).to eq(true)
      expect(row_hash['StandardDeviation']).to eq(3)
    end

    it 'defaults the displayed StandardDeviation to 2 when unset on an anomaly alarm' do
      alarm = build_alarm(anomaly_detection: true, standard_deviation: nil)
      formatter = CfnGuardian::DisplayFormatter.new([alarm])

      rows = formatter.alarms.first[:rows]
      expect(rows.to_h['StandardDeviation']).to eq(2)
    end
  end

  # Note: a correctly-deployed alarm can still appear in compare_alarms' result
  # because of a separate, pre-existing bug where the 'OkActionDisabled' row never
  # carries a deployed-side value (predates this PR, from #133) - that's why these
  # specs assert on the specific rows the anomaly-detection fix touches, rather
  # than asserting the whole comparison comes back empty.
  describe '#compare_alarms' do
    it 'stops treating Threshold as a difference for a correctly deployed anomaly alarm, and matches AnomalyDetection/StandardDeviation' do
      alarm = build_alarm(anomaly_detection: true, standard_deviation: 2)
      metric_alarm = build_metric_alarm(
        alarm: alarm,
        threshold_metric_id: 'ad1',
        band_expression: 'ANOMALY_DETECTION_BAND(m1, 2)'
      )

      formatter = CfnGuardian::DisplayFormatter.new([alarm])
      rows = formatter.compare_alarms([metric_alarm]).first[:rows]

      expect(row_by_name(rows, 'Threshold')).to be_nil

      anomaly_row = row_by_name(rows, 'AnomalyDetection')
      expect(anomaly_row).not_to be_nil
      expect(row_matches?(anomaly_row)).to eq(true)

      stddev_row = row_by_name(rows, 'StandardDeviation')
      expect(stddev_row).not_to be_nil
      expect(row_matches?(stddev_row)).to eq(true)
    end

    it 'reports a difference when the deployed StandardDeviation does not match local config' do
      alarm = build_alarm(anomaly_detection: true, standard_deviation: 4)
      metric_alarm = build_metric_alarm(
        alarm: alarm,
        threshold_metric_id: 'ad1',
        band_expression: 'ANOMALY_DETECTION_BAND(m1, 2)'
      )

      formatter = CfnGuardian::DisplayFormatter.new([alarm])
      rows = formatter.compare_alarms([metric_alarm]).first[:rows]

      expect(row_by_name(rows, 'Threshold')).to be_nil

      stddev_row = row_by_name(rows, 'StandardDeviation')
      expect(stddev_row).not_to be_nil
      expect(row_matches?(stddev_row)).to eq(false)
      expect(strip_ansi(stddev_row[1])).to eq('4.0')
      expect(strip_ansi(stddev_row[2])).to eq('2.0')
    end

    it 'reports AnomalyDetection as different when local config wants anomaly detection but the deployed alarm is still a static alarm' do
      alarm = build_alarm(anomaly_detection: true, standard_deviation: 2)
      metric_alarm = build_metric_alarm(alarm: alarm, threshold_metric_id: nil, threshold: 80.0)

      formatter = CfnGuardian::DisplayFormatter.new([alarm])
      rows = formatter.compare_alarms([metric_alarm]).first[:rows]

      anomaly_row = row_by_name(rows, 'AnomalyDetection')
      expect(anomaly_row).not_to be_nil
      expect(strip_ansi(anomaly_row[1])).to eq('true')
      expect(strip_ansi(anomaly_row[2])).to eq('false')
      expect(row_matches?(anomaly_row)).to eq(false)
    end

    it 'does not add AnomalyDetection/StandardDeviation rows for a standard (non-anomaly) alarm' do
      alarm = build_alarm(anomaly_detection: false, threshold: 80)
      metric_alarm = build_metric_alarm(alarm: alarm, threshold_metric_id: nil, threshold: 80.0)

      formatter = CfnGuardian::DisplayFormatter.new([alarm])
      rows = formatter.compare_alarms([metric_alarm]).first[:rows]

      expect(row_by_name(rows, 'AnomalyDetection')).to be_nil
      expect(row_by_name(rows, 'StandardDeviation')).to be_nil

      threshold_row = row_by_name(rows, 'Threshold')
      expect(threshold_row).not_to be_nil
      expect(row_matches?(threshold_row)).to eq(true)
    end
  end
end
