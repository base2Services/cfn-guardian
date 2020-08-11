# Composite Alarms

Composite alarms take into account a combination of alarm states and only alarm when all conditions in the rule are met. See AWS (documentation)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutCompositeAlarm.html] for rule syntax.

Using the `Composites:` top level key, create the alarm using the following syntax. 

**NOTE:** Each composite alarm cost $0.50/month

```yaml
Composites:
  
  # the key is used as the alarm name
  AlarmName:
    # Set the notification SNS topic, defaults to no notifications
    Action: Informational
    # Set a meaningful alarm description
    Description: test
    # Set the alarm rule by providing the alarm names. See above for rule syntax.
    # Use the show-state command to get a list of the alarm names.
    Rule: >-
      ALARM(guardian-alarm-1)
      AND
      ALARM(guardian-alarm-2)
```