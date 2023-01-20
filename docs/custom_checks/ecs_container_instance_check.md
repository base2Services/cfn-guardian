# ECS Container Instance Check

Source: https://github.com/base2Services/aws-lambda-ecs-container-instance-check

Checks the agent status of a ECS container instance for a ECS cluster. 
This check and alarms are created by default when a ECS cluster resource is specified in the config.

```yaml
Resources:
  ECSCluster:
  - Id: my-cluster

Templates:
  ECSCluster:
    # override the alarm defaults
    ECSContainerInstancesDisconnected:
      ...
```