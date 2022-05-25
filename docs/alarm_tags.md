# Guardian Alarm Tags

AWS tags can be applied to Cloudwatch alarms created by guardian. This is available as a separate guardian alarm because Cloudformation doesn't support creating tags on Cloudwatch alarms.

## Default Tags

Guardian will add the following default tags to each alarm

```
guardian:resource:id
guardian:resource:group
guardian:alarm:name
guardian:alarm:metric
guardian:alarm:severity
```

## Adding Tags

Additional tags can added through the alarms yaml configuration file. They can be applied globally to all alarms, to all alarms in a resource group or a specific alarm.

### Global Tags

Global tags are applied to every alarm created by guardian. Add the `GlobalTags` key at the top level of the alarms yaml config with key:value pairs. 

```yml
GlobalTags:
  key: value
  env: production
```

### Resource Group Tags

Resource group tags are applied to every alarm in a guardian resource group using the `Templates` section to add the tags.

```yaml
Templates:
  Ec2Instance:
    GroupOverrides:
      Tags:
        key: value
        env: production
```

### Specific Alarm Tags

To add tags to a specific guardian alarm you can apply the tags in the `Templates` section of the alarms yaml config.

```yaml
Templates:
  Ec2Instance:
    CPUUtilizationHigh:
      Tags:
        key: value
        alarm-action: restart ec2 instance
```

## Applying tags

To apply the tags run the `tag-alarms` command passing the alarms yaml config.

```sh
cfn-guardian tag-alarms --config alarms.yaml
```