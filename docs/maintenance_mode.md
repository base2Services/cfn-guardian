# Maintenance Mode

CloudWatch alarms can be enabled and disabled to allow maintenance periods without getting alert notifications.
Alarms can be provided to the function the following ways

## Alarm Names

Alarm names be provided by a space delimited list using the `--alarms` switch.

```bash
cfn-guardian disable-alarms --group alarm-1 alarm-2
cfn-guardian enable-alarms --group alarm-1 alarm-2
```

## Alarm Name Prefix

Alarm name prefix will find the alarms in the account and region that start with the provided string.
This can be useful if required to disable all guardian alarms, disable all alarm for a resource group or for a specific resource.
Alarm names are created using the following convention.

`guardian` - `ResourceGroupName` - `ResourceId` or `FriendlyName` - `AlarmName` 

The following example would disable/enable all alarms for all ECS Services

```bash
cfn-guardian disable-alarms --alarm-prefix guardian-ECSService
cfn-guardian enable-alarms --alarm-prefix guardian-ECSService
```

The following example would disable/enable all alarms for the ECS Service app

```bash
cfn-guardian disable-alarms --alarm-prefix guardian-ECSService-app
cfn-guardian enable-alarms --alarm-prefix guardian-ECSService-app
```

## Maintenance Groups

Maintenance groups are defined in the YAML configuration file and creates a logical mapping between alarms.

```yaml
Resources:
  
  ApplicationTargetGroup:
  - Id: app-tg
    LoadBalancer: public-lb
    
  AutoScalingGroup:
  - Id: ecs-asg
  
  ECSCluster:
  - Id: prod
  
  ECSService:
  - Id: app
    Cluster: prod
  
  Http:
  - Id: https://myapp.com
    StatusCode: 200

# Define the top level key
MaintenaceGroups:
  
  # Define the group name
  AppUpdate:
    # Define the resource group
    ECSService:
      # define the alarms in the resource group
      UnhealthyTaskCritical:
      # define the resource id's
      - Id: app
      # or the friendly name
      - Name: app
    Http:
      EndpointAvailable:
      - Id: https://myapp.com
      EndpointStatusCodeMatch:
      - Id: https://myapp.com
```

```bash
cfn-guardian disable-alarms --group AppUpdate
cfn-guardian enable-alarms --group AppUpdate
```