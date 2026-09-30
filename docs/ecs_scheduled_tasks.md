# ECS Scheduled Tasks

`ECSScheduledTask` monitors ECS tasks that run outside of an ECS service, for example tasks launched on a schedule by an EventBridge rule or EventBridge Scheduler. These tasks have no service to attach `ECSService` alarms to, so Guardian watches the `ECS Task State Change` events for the cluster instead and notifies when a task fails.

## Configuration

```yaml
Resources:
  ECSScheduledTask:
  # Id is the ECS cluster name. Monitors every standalone task in the cluster.
  - Id: batch-jobs
  # Optionally narrow to a single task definition family.
  - Id: shared-cluster
    TaskDefinitionFamily: report-export
```

| Key | Required | Description |
|---|---|---|
| `Id` | yes | ECS cluster name |
| `TaskDefinitionFamily` | no | Only match tasks from this task definition family, matched on the task definition ARN |

Every event subscription in this group, including custom ones, is scoped to:

- the cluster in `Id`
- tasks not started by an ECS service (the task's `group` doesn't start with `service:`), so service deployments don't trigger alerts
- the `TaskDefinitionFamily`, if set

If a scheduled task is launched with a custom `group` starting with `service:`, it won't be matched.

## Default Event Subscriptions

Both are sent to the `Events` topic by default.

| Name | Fires when |
|---|---|
| `TaskFailed` | A task stops and any of its containers has a non-zero exit code |
| `TaskFailedToStart` | A task stops with stop code `TaskFailedToStart`, e.g. the image can't be pulled or a secret can't be fetched |

EventBridge matches `exitCode` against every container in the task, so a sidecar (such as a log router) that exits non-zero will also trigger `TaskFailed`.

## Overriding Defaults

Event subscriptions are configured under the `EventSubscriptions` key. See [event subscriptions](event_subscriptions.md).

```yaml
EventSubscriptions:
  ECSScheduledTask:
    # page on failed runs instead of sending to the Events topic
    TaskFailed:
      Topic: Critical
    # disable the failed-to-start notification
    TaskFailedToStart: false
    # custom subscriptions default to the ECS Task State Change detail type
    # and are scoped to the cluster and family like the defaults
    TaskStoppedBySpot:
      Detail:
        stopCode: [SpotInterruption]
```

## Alarms

There are no default alarms, as scheduled tasks only publish metrics while they run. If [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html) is enabled on the cluster, alarms can be added under `Templates`. They use the `ECS/ContainerInsights` namespace with the `ClusterName` dimension, plus `TaskDefinitionFamily` if set, and treat missing data as not breaching.

```yaml
Templates:
  ECSScheduledTask:
    MemoryUtilizedHigh:
      MetricName: MemoryUtilized
      Statistic: Maximum
      Threshold: 1800 # MiB
      AlarmAction: Warning
```

## Missed Runs

The event subscriptions only fire when a task runs and fails. They won't fire if the schedule never launches a task. If `RunTask` itself fails (for example on a bad network configuration), ECS creates no task and emits no events. That shows up in the EventBridge rule's or schedule's `FailedInvocations` metric instead.

To catch a missed run, add a `LogGroup` metric filter that counts a line the task logs on success, and alarm when the count is below 1 over the schedule interval. A metric filter with no matches publishes no data, so the alarm must treat missing data as breaching. See [log group metric filters](custom_checks/log_group_metric_filters.md).

```yaml
Resources:
  LogGroup:
  - Id: batch-jobs
    MetricFilters:
    - MetricName: ReportExportSucceeded
      Pattern: '"export complete"'

Templates:
  LogGroup:
    ReportExportSucceeded:
      ComparisonOperator: LessThanThreshold
      Threshold: 1
      Period: 86400 # the schedule interval, here daily
      EvaluationPeriods: 1
      TreatMissingData: breaching
      AlarmAction: Warning
```
