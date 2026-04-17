# Search Expression Alarms

Search expression alarms use CloudWatch [SEARCH()](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/search-expression-syntax.html) to dynamically match metrics instead of targeting a fixed set of dimensions. This is useful when the physical resource ID changes between deployments, such as Auto Scaling Groups that use replacement update policies in CloudFormation.

## The Problem

When a CloudFormation stack replaces an ASG on deployment, the physical ASG name changes (e.g. `my-app-AsgGroup-abc123` becomes `my-app-AsgGroup-xyz789`). Standard alarms use fixed dimensions that reference the exact ASG name, so they break after every deployment until Guardian is recompiled and redeployed with the new name.

## How It Works

Instead of emitting a CloudWatch alarm with fixed `Dimensions`, `MetricName`, `Namespace`, and `Statistic` properties, a search expression alarm emits the CloudFormation `Metrics` property (a list of `MetricDataQuery` objects) with:

1. A **SEARCH()** expression that dynamically matches metrics by partial or exact name
2. An **aggregation function** (e.g. `MAX`, `AVG`, `SUM`) that reduces the matched metrics to a single time series for threshold evaluation

## Configuration

Add `SearchExpression` and optionally `SearchAggregation` to an alarm template. When `SearchExpression` is set, the `Dimensions`, `MetricName`, `Namespace`, `Statistic`, and `Period` properties are not used since CloudWatch treats these as mutually exclusive with the alarm `Metrics` property.

### Properties

| Property | Required | Default | Description |
|---|---|---|---|
| `SearchExpression` | Yes | - | A CloudWatch SEARCH() expression string. Supports `${Resource::...}` [variables](variables.md). |
| `SearchAggregation` | No | `MAX` | Aggregation function applied to the search results. Valid values: `MAX`, `MIN`, `AVG`, `SUM`. |

### Overriding Default Alarms

You can convert existing default alarms to use search expressions by overriding them in the template:

```yaml
Resources:
  AutoScalingGroup:
    - Id: my-app-AsgGroup

Templates:
  AutoScalingGroup:
    CPUUtilizationHighBase:
      SearchExpression: "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" \"${Resource::Id}\"', 'Minimum', 60)"
      SearchAggregation: MAX
    StatusCheckFailed:
      SearchExpression: "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"StatusCheckFailed\" \"${Resource::Id}\"', 'Maximum', 60)"
      SearchAggregation: MAX
```

In this example the `Id` is the stable prefix of the ASG name. The double quotes around `\"${Resource::Id}\"` inside the SEARCH expression perform an exact substring match, so `my-app-AsgGroup-abc123` and `my-app-AsgGroup-xyz789` both match but unrelated ASGs do not.

### Creating New Alarms

You can also create new search expression alarms that don't override any defaults:

```yaml
Templates:
  AutoScalingGroup:
    NetworkOutHigh:
      SearchExpression: "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"NetworkOut\" \"${Resource::Id}\"', 'Average', 300)"
      SearchAggregation: SUM
      Threshold: 1000000000
      ComparisonOperator: GreaterThanThreshold
      EvaluationPeriods: 3
      AlarmAction: Warning
```

### Using With Other Resource Groups

Search expressions work with any resource group, not just AutoScalingGroup:

```yaml
Resources:
  ECSService:
    - Id: my-service
      Cluster: my-cluster

Templates:
  ECSService:
    CPUUtilizationHigh:
      SearchExpression: "SEARCH('{AWS/ECS,ServiceName,ClusterName} MetricName=\"CPUUtilization\" \"${Resource::Id}\"', 'Average', 60)"
      SearchAggregation: MAX
      Threshold: 90
      EvaluationPeriods: 5
```

## Variables

`${Resource::...}` variables are interpolated inside search expressions the same way as in [dimension variables](variables.md). You can reference any key from the resource definition:

```yaml
Resources:
  AutoScalingGroup:
    - Id: my-app-AsgGroup
      Environment: production

Templates:
  AutoScalingGroup:
    CPUUtilizationHighBase:
      SearchExpression: "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" \"${Resource::Id}\"', 'Minimum', 60)"
      SearchAggregation: MAX
```

## CloudWatch SEARCH() Syntax Quick Reference

The general format is:

```
SEARCH('{Namespace,DimensionName} SearchTerm', 'Statistic', Period)
```

- **Partial match**: `my-app` matches any metric with a token `my` or `app` in any dimension value
- **Exact match**: `"my-app-AsgGroup"` matches only the exact substring `my-app-AsgGroup`
- **Boolean operators**: `AND`, `OR`, `NOT` can be used to combine terms
- **Property designators**: `MetricName="CPUUtilization"` restricts matching to the metric name

See the [CloudWatch search expression syntax documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/search-expression-syntax.html) for full details.

## Limitations

- **2-week lookback**: SEARCH() only finds metrics that have reported data within the last 2 weeks
- **100 metric limit**: A single SEARCH expression can match up to 100 time series
- **1024 character limit**: The search expression query string cannot exceed 1024 characters
- **Aggregation required**: Since SEARCH can return multiple time series, the aggregation function reduces them to a single series for threshold comparison
