# CfnGuardian

CfnGuardian is a AWS monitoring tool with a few capabilities:

- creates cloudwatch alarms through cloudformation based upon resources defined in a YAML config
- alerting through SNS using 4 levels of severity [ Critical, Warning, Task, Informational ]  
- has a standard set of default alarms across many AWS resources
- creates custom metrics for external checks through lambda functions such as
    - http endpoint availability
    - http status code matching 
    - http body regex matching
    - domain expiry
    - ssl expiry
    - sql query
    - nrpe

**Supported AWS Resources**

- AmazonMq
- ApiGateway
- Application Targetgroups
- Network TargetGroups
- AutoScalingGroups
- CloudFront Distributions
- DynamoDB Tables
- EC2 Instances
- ECS Clusters
- ECS Services
- EFS
- Classic LoadBalancers
- Lambda Functions
- RDS Clusters
- RDS Instances
- Redshift Cluster
- SQS Queues

## Installation

```ruby
gem install cfn-guardian
```

## Commands

**compile**

```bash
Usage:
  cfn-guardian compile c, --config=CONFIG

Options:
  c, --config=CONFIG                 # yaml config file
      [--validate], [--no-validate]  # validate cfn templates
                                     # Default: true
      [--bucket=BUCKET]              # provide custom bucket name, will create a default bucket if not provided
  r, [--region=REGION]               # set the AWS region

Description:
  Generates CloudFormation templates from the alarm configuration and output to the out/ directory.
```

**deploy**

```bash
Usage:
  cfn-guardian deploy c, --config=CONFIG

Options:
  c, --config=CONFIG                           # yaml config file
      [--bucket=BUCKET]                        # provide custom bucket name, will create a default bucket if not provided
  r, [--region=REGION]                         # set the AWS region
  r, [--stack-name=STACK_NAME]                 # set the Cloudformation stack name. Defaults to `guardian`
      [--sns-critical=SNS_CRITICAL]            # sns topic arn for the critical alamrs
      [--sns-warning=SNS_WARNING]              # sns topic arn for the warning alamrs
      [--sns-task=SNS_TASK]                    # sns topic arn for the task alamrs
      [--sns-informational=SNS_INFORMATIONAL]  # sns topic arn for the informational alamrs

Description:
  Generates CloudFormation templates from the alarm configuration and output to the out/ directory. Then copies the files to the s3 bucket and deploys the cloudformation.
```

## Configuration

Config is stored in a standard YAML file which will default to `alarms.yaml`. This can be overridden by supplying the `--config` switch.

### AWS Resources

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

### Custom Metric Resources

These are also defined under the resources key but more detail is required and differs per group.

**Http**

Cloudwatch NameSpace: `HttpCheck`

```yaml
Resources:
  Http:
  # Array of resources defining the http endpoint with the Id: key
  - Id: https://api.example.com
    # enables the status code check
    StatusCode: 200
    # enables the SSL check
    Ssl: true
  - Id: https://www.example.com
    StatusCode: 301
  - Id: https://example.com
    StatusCode: 200
    Ssl: true
    # enables the body regex check
    BodyRegex: 'helloworld'
```

**DomainExpiry**

Cloudwatch NameSpace: `DNS`

```yaml
Resources:
  DomainExpiry:
  # Array of resources defining the domain with the Id: key
  - Id: example.com
```

**Nrpe**

Cloudwatch NameSpace: `NRPE`

*Note: This requires the nrpe agent running and configured on your EC2 Host*

```yaml
Resources:
  Nrpe:
  # Array of host groups with the uniq identifier of Environment.
  # This will create a nrpe lambda per group attach to the defined vpc and subnets
  - Environment: Prod
    # VPC id for the vpc the EC2 hosts are running in
    VpcId: vpc-1234
    # Array of subnets to attach to the lambda function. Supply multiple if you want to be multi AZ. 
    # Multiple subnets from the same AZ cannot be used!
    Subnets:
      - subnet-abcd
    Hosts:
    # Array of hosts with the Id: key defining the host private ip address
    - Id: 10.150.10.6
      # Array of nrpe commands to run against the host.
      # A custom metric and alarm is created for each command
      Commands:
        - check_disk
    - Id: 10.150.10.6
      Commands:
        - check_disk
```

**Sql**

Cloudwatch NameSpace: `SQL`

```yaml
Resources:
  Sql:
  # Array of host groups with the uniq identifier of Environment.
  # This will create a sql lambda per group attach to the defined vpc and subnets
  - Environment: Prod
    # VPC id for the vpc the EC2 hosts are running in
    VpcId: vpc-1234
    # Array of subnets to attach to the lambda function. Supply multiple if you want to be multi AZ. 
    # Multiple subnets from the same AZ cannot be used!
    Subnets:
      - subnet-1234
    Hosts:
    # Array of hosts with the Id: key defining the host private ip address
    - Id: my-rds-instance.example.com
      # Secret manager secret where the sql:// connection string key:value is defined
      # { "connectionString": "sql://username:password@mydb:3306/information_schema"}
      SecretId: MyTestDatabaseSecret
      # Database engine. supports mysql | postgres | mssql
      Engine: mysql
      Queries:
      # Array of SQL queries
      # MetricName used to create the custom metric and alarm
      - MetricName: LongRunningTransactions
        # SQL Query to execute
        Query: >-
          SELECT pl.host,trx_id,trx_started,trx_query 
          FROM information_schema.INNODB_TRX it INNER 
          JOIN information_schema.PROCESSLIST pl 
          ON pl.Id=it.trx_mysql_thread_id 
          WHERE it.trx_started < (NOW() - INTERVAL 4 HOUR);
```

Create secretmanager secret:

```bash
aws secretsmanager create-secret --name MyTestDatabaseSecret \
    --description "My test database secret for use with guardian sql check" \
    --secret-string '{"connectionString":"sql://username:password@mydb:3306/information_schema"}'
```

## Alarm Templates

Each resource group has a set of default alarm templates which defines all the cloudwatch alarm options such as Threshold, Statistic, EvaluationPeriods etc. These can be manipulated in a few ways to change the values or create new alarms. 

Custom alarm templates are defined within the same YAML config file un the `Templates` key.

### Overriding Defaults

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # define the Alarm name you want to override
    CPUUtilizationHigh:
      # supply the key value of the alarm property you want to override
      Threshold: 80
```

### Creating A New Alarm From A Default

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

### Creating A New Alarm With No Defaults

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

### Disabling An Alarm

You can disable an alarm by setting the alarm to `false`

```yaml
Templates:
  # define the resource group
  Ec2Instance:
    # define the Alarm and set the value to false
    CPUUtilizationHigh: false
```

### Creating A New Resource Group

You can create a new resource group based upon an existing resource group. For example if you had 2 target groups and wanted to disable an alarm for one but not the other you can create a new resource group which will inherit all the ApplicationTargetGroup alarms and the disabled the select alarm.

```yaml
Resources:
  # the default resource group
  ApplicationTargetGroup:
  - Id: ApiTG
    LoadBalancer: MyPublicLB
  - Id: WebTG
    LoadBalancer: MyPublicLB
  - Id: ServiceTG
    LoadBalancer: MyPublicLB
  
  # my new custom resource group
  RedirectTargetGroup:
  - Id: RedirectTG
    LoadBalancer: MyPublicLB
    
Templates:
  # create the new resource group
  RedirectTargetGroup:
    # inherit the ApplicationTargetGroup resource group
    Inherit: ApplicationTargetGroup
    # disable the selected alarm
    TargetResponseTime: false
```

## SNS Topics

Create the topics before launching the guardian stack

```bash
aws sns create-topic --name Guardian-Critical
aws sns create-topic --name Guardian-Warning
aws sns create-topic --name Guardian-Task
aws sns create-topic --name Guardian-Informational
```

SNS topics can be defined in the YAML config or during the `deploy` command using the sns switches. The full ARN must be used.

```yaml
Topics:
  Critical: arn:aws:sns:ap-southeast-2:111111111111:Guardian-Critical
  Warning: arn:aws:sns:ap-southeast-2:111111111111:Guardian-Warning
  Task: arn:aws:sns:ap-southeast-2:111111111111:Guardian-Task
  Informational: arn:aws:sns:ap-southeast-2:111111111111:Guardian-Informational
``` 

## Severities

Severties are defined in each alarm sing the `AlarmAction` key. There are 4 options `[ Critical, Warning, Task, Informational ]`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/base2services/cfn-guardian.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
