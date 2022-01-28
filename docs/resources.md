# Resources

Resources are AWS resources grouped by the resource type such as `RDSInstance`, `Ec2Instance`, `ApplicationTargetGroup` etc. These are defined under the top level key `Resources` in the yaml config file. The resource group is then used to generate standard set of alarms.

Custom resource groups can be created however matching alarm templates must be created to create alarms.

## Resource lookup

Resources can be looked up within an account using the tool [monitorable](https://github.com/base2Services/monitorable). This tool will scan every region within an account for AWS resources that can be monitored and return a valid Guardian yaml config using the `--format cfn-guardian` flag.

```sh
./monitorable.py --format cfn-guardian
```

## YAML Configuration

The resources key is where the resources are defined.

```yaml
Resources:
  # resource group
  Ec2Instance:
  # Array of resources defining the resource id with the Id: key
  - Id: i-1a2b3c4d5e
```

There are some resources that require more that the resource id to generate the alarm, for these cases addition key:values are required.

```yaml
Resources:
  ApplicationTargetGroup:
  - Id: target-group-id
    # Target group requires the loadbalancer id for the alarm
    Loadbalancer: app/application-loadbalancer-id
```

| Resource Group              | Require Keys     |
| --------------------------- | ---------------- |
| ApiGateway                  | Id               |
| AmazonMQBroker              | Id               |
| AutoScalingGroup            | Id               |
| DocumentDBCluster           | Id               |
| DynamoDBTable               | Id               |
| ElastiCacheReplicationGroup | Id               |
| ElasticFileSystem           | Id               |
| Ec2Instance                 | Id               |
| EcsCluster                  | Id               |
| EcsService                  | Id, Cluster      |
| NetworkTargetGroup          | Id, LoadBalancer |
| ApplicationTargetGroup      | Id, LoadBalancer |
| ElasticLoadBalancer         | Id               |
| RDSInstance                 | Id               |
| RDSClusterInstance          | Id               |
| RedshiftCluster             | Id               |
| Lambda                      | Id               |
| CloudFrontDistribution      | Id               |
| SQSQueue                    | Id               |
| ElasticSearch               | Id, Domain       |


## Custom Resource Groups

You may want to create a custom resource group if some of the resources require differewnt alarm configurations. To create a custom resource group create new name for the group and add the resources, then create the alarm template and inherit the desired alarms.

```yaml
Resources:
  # default resource group
  Ec2Instance:
  - Id: i-1a2b3c4d5e
  - Id: i-9z8y7x6w5v
  # custom resource group
  CustomEc2Instance:
  - Id: i-6fefg5qe4e

Templates:
  # create a new alarm template with the same group name 
  CustomEc2Instance:
    # inherit the ec2 alarms
    Inherit: Ec2Instance
    # alter the alarms
    CPUUtilizationHigh: false
```

## Friendly Resource Names

You can set a friendly name which will replace the resource id in the alarm name.
The resource id will still be available in the alarm description.

```yaml
Resources:
  ApplicationTargetGroup:
  - Id: target-group-id
    Loadbalancer: app/application-loadbalancer-id
    Name: webapp
```