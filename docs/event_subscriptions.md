# Event Subscriptions

Event subscriptions create cloudwatch events that are triggered by AWS resources such as a EC2 instance termination.


## Defaults Events

As with the default alarms in Guardian, there are default events for some resource types. These events are deployed by default for each of the resources unless the event is disabled.


## Overriding Defaults

Default properites of the events can be overridden through the config YAML using the `EventsSubscription` top level key.
For example here we are changing the topic the event is being send to.

```yaml
Topics:
    CustomEvents: arn:aws:sns....

EventSubscription:
  Ec2Instance:
    InstanceTerminated:
      Topic: CustomEvents
```

## Disabling Default Events

Default events can be disabled, the same way default alarms can be disabled through the config YAML.

```yaml
EventSubscription:
  Ec2Instance:
    # set the instance terminated event to false to disable the event
    InstanceTerminated: false
```

## Creating Custom Events

Custom events can be created if there are not defaults for that event. They can be inherited from a default event or from the base event model.

### Inheriting From Default Event

This is useful if you want to create a new event and a default event already has the same format as the new event you want to create.
The following example inherits the `MasterPasswordReset` RDS event and creates a new event that captures the security group add to an rds instance event.

```yaml
EventSubscription:
  RDSInstance:
    # Create a new event name
    DBNewSecurityGroup:
      # inherit the event
      Inherit: MasterPasswordReset
      # alter the required properties
      Message: The DB instance has been added to a security group.
```

### Create Event From Scratch

If there are no default events that match the format you require you can create an event of the base event subscription model.

```yaml
EventSubscription:
  ECSCluster:
    ContainerInstanceStateChange:
      Source: aws.ecs
      DetailType: ECS Container Instance State Change
```