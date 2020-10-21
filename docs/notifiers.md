# Guardian Notifiers

## SNS Notification

There are 4 default notification levels used by Guardian Critical, Warning, Task, Informational. If you wish to recieve notifications for each of these you need to supply an sns topic arn in the alarms.yaml

```yaml
Topics:
  Critical: arn:aws:sns:ap-southeast-2:123456789012:Critical
  Warning: arn:aws:sns:ap-southeast-2:123456789012:Warning
  Task: arn:aws:sns:ap-southeast-2:123456789012:Task
  Informational: arn:aws:sns:ap-southeast-2:123456789012:Informational
```

Each alarm has a default notification level but can be overriden in the config using the `AlarmAction` property at either the alarm group or alarm level. See the [Overriding Defaults](#overriding-defaults) section on how to do that.

You can add your own notification topics to the topics section and combine them with the existing topics. `AlarmAction` property will accept both a string and array of notication topics.

```yaml
Topics:
  Critical: arn:aws:sns:ap-southeast-2:123456789012:Critical
  Warning: arn:aws:sns:ap-southeast-2:123456789012:Warning
  Task: arn:aws:sns:ap-southeast-2:123456789012:Task
  Informational: arn:aws:sns:ap-southeast-2:123456789012:Informational
  Custom: arn:aws:sns:ap-southeast-2:123456789012:Custom

Template:
  Ec2Instance:
    GroupOverrides:
      AlarmActions:
      - Critical
      - Custom
```
