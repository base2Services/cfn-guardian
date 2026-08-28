# Anomaly Detection Alarms

Anomaly detection alarms use CloudWatch [anomaly detection](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html) to alarm on a metric's expected behaviour rather than a fixed number. CloudWatch builds a model of the metric's normal range (a "band") from up to two weeks of history and the alarm fires when the metric strays outside that band, instead of crossing a static `Threshold`.

## The Problem

A static `Threshold` works well when "too high" or "too low" is a known constant, but many metrics (queue depth, request count, CPU on a workload with a daily cycle) have a normal range that varies by time of day or day of week. A fixed threshold set high enough to avoid false alarms on the daily peak is too high to catch a real problem during the trough, and vice versa.

## How It Works

Instead of emitting a CloudWatch alarm with a static `Threshold`, an anomaly detection alarm emits the CloudFormation `Metrics` property (a list of `MetricDataQuery` objects) with:

1. A `MetricStat` entry (`m1`) that returns the raw metric, built from the alarm's usual `MetricName`, `Namespace`, `Dimensions`, `Period` and `Statistic`.
2. An `ANOMALY_DETECTION_BAND(m1, <StandardDeviation>)` expression entry (`ad1`) that computes the expected value band for that metric.

The alarm then sets `ThresholdMetricId: ad1` instead of a `Threshold`, and compares the metric against the band using one of the anomaly-specific `ComparisonOperator` values. This implicitly creates the underlying `AWS::CloudWatch::AnomalyDetector` model in CloudWatch - no separate CloudFormation resource is required.

## Configuration

Add `AnomalyDetection: true` and a `ComparisonOperator` to an alarm template. Optionally set `StandardDeviation` to control the width of the expected band.

### Properties

| Property | Required | Default | Description |
| --- | --- | --- | --- |
| `AnomalyDetection` | Yes | `false` | Set to `true` to alarm on an anomaly detection band instead of a static Threshold. |
| `StandardDeviation` | No | `2` | The width of the expected value band, in standard deviations. A larger number widens the band (fewer, larger anomalies alarm); a smaller number narrows it. |
| `ComparisonOperator` | Yes | - | Must be one of `GreaterThanUpperThreshold`, `LessThanLowerThreshold`, or `LessThanLowerOrGreaterThanUpperThreshold`. |

`Threshold` must not be set on an anomaly detection alarm - CloudFormation treats `Threshold` and `ThresholdMetricId` as mutually exclusive, and `cfn-guardian` will fail validation if both are supplied.

### Overriding Default Alarms

You can convert an existing default alarm to use anomaly detection by overriding it in the template:

```yaml
Templates:
  Ec2Instance:
    CPUUtilizationHigh:
      AnomalyDetection: true
      StandardDeviation: 2
      ComparisonOperator: GreaterThanUpperThreshold
      EvaluationPeriods: 3
```

### Creating New Alarms

You can also create new anomaly detection alarms that don't override any defaults. `MetricName` and `Namespace` are still required, the same as any other alarm, since they identify the metric CloudWatch builds the anomaly detection model from:

```yaml
Templates:
  SQSQueue:
    ApproximateNumberOfMessagesVisibleAnomaly:
      MetricName: ApproximateNumberOfMessagesVisible
      Statistic: Average
      AnomalyDetection: true
      StandardDeviation: 3
      ComparisonOperator: LessThanLowerOrGreaterThanUpperThreshold
      EvaluationPeriods: 3
      DatapointsToAlarm: 2
      AlarmAction: Warning
```

## Choosing A Comparison Operator

- `GreaterThanUpperThreshold` - alarm only when the metric goes above the expected band (e.g. an unexpected spike in queue depth or error count).
- `LessThanLowerThreshold` - alarm only when the metric drops below the expected band (e.g. request count dropping to zero when traffic is expected).
- `LessThanLowerOrGreaterThanUpperThreshold` - alarm on either side of the band. This is the most common choice when you don't know in advance which direction is abnormal.

## Limitations

- **Training period**: CloudWatch needs data to learn the metric's normal pattern; a newly created anomaly detector can take some time (often a few hours, up to a few days for metrics with a weekly pattern) before the band is reliable.
- **Cannot combine with `SearchExpression`**: both features rely on the alarm's `Metrics` property, so `AnomalyDetection` and `SearchExpression` cannot be set on the same alarm.
- See the [CloudWatch anomaly detection documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html) for how the model is trained and how to inspect it in the console.
