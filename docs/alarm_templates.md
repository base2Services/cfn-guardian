# Guardian Alarm Templates

Each resource group has a set of default alarm templates which defines all the cloudwatch alarm options such as Threshold, Statistic, EvaluationPeriods etc. These can be manipulated in a few ways to change the values or create new alarms. They are defined under the top level key `Templates` in the yaml config file.

## Alarm Defaults

To list the default alarms use the `show-alarms` command with the `--defaults` switch.
The list can be filtered using the `--group ApplicationTargetGroup` and `--alarm TargetResponseTime` optional switches

```sh
cfn-guardian show-alarms --defaults --group ApplicationTargetGroup --alarm TargetResponseTime

+-------------------------+----------------------------------+
|         ApplicationTargetGroup::TargetResponseTime         |
| guardian-ApplicationTargetGroup-Default-TargetResponseTime |
+-------------------------+----------------------------------+
| Property                | Config                           |
+-------------------------+----------------------------------+
| ResourceId              | Default                          |
| ResourceHash            | 7a1920d61156abc05a60135aefe8bc67 |
| Enabled                 | true                             |
| MetricName              | TargetResponseTime               |
| Dimensions              |                                  |
| Threshold               | 5                                |
| Period                  | 60                               |
| EvaluationPeriods       | 5                                |
| ComparisonOperator      | GreaterThanThreshold             |
| Statistic               | Maximum                          |
| ActionsEnabled          | true                             |
| AlarmAction             | Critical                         |
| TreatMissingData        | notBreaching                     |
+-------------------------+----------------------------------+
```

## Overriding Defaults

Alarm properties such as `Threshold`, `AlarmAction`, etc can be overriden at the alarm level or at the alarm group level. 

### Alarm Group Overrides

Alarm group level overrides apply to all alarms within the alarm group. 

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # GroupOverrides key denotes the group level overrides
    GroupOverrides:
      # supply the key value of the alarm property you want to override
      AlarmAction: Informational
```

### Alarm Overrides

Alarm overrides apply only to the alarm the property is applied to. This will override any alarm group level overrides.

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # define the Alarm name you want to override
    CPUUtilizationHigh:
      # supply the key value of the alarm property you want to override
      Threshold: 80
```

## Creating A New Alarm From A Default

You can create a default alarm from a default alarm using the `Inherit:` key. This will inherit all properites from the default alarm which can then be overridden.

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # define the Alarm name you want to override
    CPUUtilizationWarning:
      # Inherit the CPUUtilizationHigh alarm
      Inherit: CPUUtilizationHigh
      # supply the key value of the alarm property you want to override
      Threshold: 75
      EvaluationPeriods: 60
      AlarmAction: Warning
```

## Creating A New Alarm With No Defaults

You can create a new alarm with out inheriting an existing one. This will the inherit the default properties for the resource group.

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # define the Alarm name you want to override
    CPUUtilizationWarning:
      # metric name must be provided
      MetricName: CPUUtilization
      # supply the key value of the alarm property you want to override
      Statistic: Minimum
      Threshold: 75
      EvaluationPeriods: 60
      AlarmAction: Warning
```

## Disabling An Alarm

You can disable an alarm by setting the alarm to `false`

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # define the Alarm and set the value to false
    CPUUtilizationHigh: false
```

## M Out Of N Metric Data Points

This can be good to alert on groups of spikes with in a certain time frame without getting alerts for individual spikes.
It works by setting the `EvaluationPeriods` as N value and `DatapointsToAlarm` as the M value. 
The following example will trigger the alarm if 6 out of 10 data points crossed the threshold of 90% CPU utilisation in a 10 minute period.

```yaml
Templates:
  Ec2Instance:
    CPUUtilizationHigh:
      Threshold: 90
      Period: 60
      EvaluationPeriods: 10
      DatapointsToAlarm: 6
```