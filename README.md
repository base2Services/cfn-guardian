# CfnGuardian

CfnGuardian is a AWS monitoring tool with a few capabilities:

- creates cloudwatch alarms through cloudformation based upon resources defined in a YAML config
- alerting through SNS using 4 levels of severity [ Critical, Warning, Task, Informational ]  
- has a standard set of default alarms across many AWS resources
- creates cloudwatch log metric filters with default alarms
- creates custom metrics for external checks through lambda functions such as
    - http endpoint availability
    - http status code matching 
    - http body regex matching
    - domain expiry
    - ssl expiry
    - sql query
    - nrpe
    - sftp availability
    - sftp file download
    - tls version checking

**Supported AWS Resources**

- AmazonMq
- ApiGateway
- ApiGatewayPath (Resource Methods)
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
- LogGroup Metric Filters

## Installation

```ruby
gem install cfn-guardian
```

## Commands

**compile**

Generates CloudFormation templates from the alarm configuration and output to the out/ directory.

```bash
Usage:
  cfn-guardian compile c, --config=CONFIG

Options:
  c, --config=CONFIG                 # yaml config file
      [--validate], [--no-validate]  # validate cfn templates
                                     # Default: true
      [--bucket=BUCKET]              # provide custom bucket name, will create a default bucket if not provided
  r, [--region=REGION]               # set the AWS region
      [--debug], [--no-debug]        # enable debug logging
```

**deploy**

Generates CloudFormation templates from the alarm configuration and output to the out/ directory. Then copies the files to the s3 bucket and deploys the Cloudformation.

```bash
Usage:
  cfn-guardian deploy c, --config=CONFIG

Options:
  c, --config=CONFIG                           # yaml config file
      [--bucket=BUCKET]                        # provide custom bucket name, will create a default bucket if not provided
  r, [--region=REGION]                         # set the AWS region
  s, [--stack-name=STACK_NAME]                 # set the Cloudformation stack name. Defaults to `guardian`
      [--sns-critical=SNS_CRITICAL]            # sns topic arn for the critical alamrs
      [--sns-warning=SNS_WARNING]              # sns topic arn for the warning alamrs
      [--sns-task=SNS_TASK]                    # sns topic arn for the task alamrs
      [--sns-informational=SNS_INFORMATIONAL]  # sns topic arn for the informational alamrs
      [--debug], [--no-debug]                  # enable debug logging
```

**show-alarms**

Displays the configured settings for each alarm. Can be filtered by resource group and alarm name. Defaults to show all configured alarms.

```bash
Usage:
  cfn-guardian show-alarms c, --config=CONFIG

Options:
  c, --config=CONFIG                 # yaml config file
  g, [--group=GROUP]                 # resource group
  a, [--alarm=ALARM]                 # alarm name
      [--id=ID]                      # resource id
      [--compare], [--no-compare]    # compare config to deployed alarms
      [--defaults], [--no-defaults]  # show default alarm and properites
      [--debug], [--no-debug]        # enable debug logging
```

**show-history**

Displays the alarm state or config history for the last 7 days. Alarms can be described in 2 different ways:

1. Using the config to describe the alarms and filter via the group, alarm and resource id. 
2. Supplying a list of alarm names with the `--alarm-names` option.

*NOTE: Options 2 may find alarms not in the guardian stack.*

```bash
Usage:
  cfn-guardian show-history

Options:
  c, [--config=CONFIG]               # yaml config file
  g, [--group=GROUP]                 # resource group
  a, [--alarm=ALARM]                 # alarm name
      [--alarm-names=one two three]  # CloudWatch alarm name if not providing config
      [--id=ID]                      # resource id
  t, [--type=TYPE]                   # filter by alarm state
                                     # Default: state
                                     # Possible values: state, config
      [--debug], [--no-debug]        # enable debug logging
```

**show-state**

Displays the current CloudWatch alarm state. Alarms can be described in 3 different ways:

1. Using the config to describe the alarms and filter via the group, alarm and resource id. 
2. Supplying a list of alarm names with the `--alarm-names` option.
3. Supplying the alarm name prefix using the `--alarm-prefix` option. For example `--alarm-prefix ECS` will find all the ECSCluster related alarms.

*NOTE: Options 2 and 3 may find alarms not in the guardian stack.*

```bash
Usage:
  cfn-guardian show-state

Options:
  c, [--config=CONFIG]               # yaml config file
  g, [--group=GROUP]                 # resource group
  a, [--alarm=ALARM]                 # alarm name
      [--id=ID]                      # resource id
  s, [--state=STATE]                 # filter by alarm state
                                     # Possible values: OK, ALARM, INSUFFICIENT_DATA
      [--alarm-names=one two three]  # CloudWatch alarm name if not providing config
      [--alarm-prefix=ALARM_PREFIX]  # CloudWatch alarm name prefix if not providing config
      [--debug], [--no-debug]        # enable debug logging
```

**show-drift**

Displays any Cloudformation drift detection in the CloudWatch alarms from the deployed stacks.

```bash
Usage:
  cfn-guardian show-drift

Options:
  s, [--stack-name=STACK_NAME]  # set the Cloudformation stack name
                                # Default: guardian
      [--debug], [--no-debug]   # enable debug logging
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

| Resource Group              | Require Keys                     |
| --------------------------- | -------------------------------- |
| ApiGateway                  | Id                               |
| ApiGatewayPath              | ApiName, Stage, Resource, Method |
| AmazonMQBroker              | Id                               |
| AutoScalingGroup            | Id                               |
| DynamoDBTable               | Id                               |
| ElastiCacheReplicationGroup | Id                               |
| ElasticFileSystem           | Id                               |
| Ec2Instance                 | Id                               |
| EcsCluster                  | Id                               |
| EcsService                  | Id, Cluster                      |
| NetworkTargetGroup          | Id, LoadBalancer                 |
| ApplicationTargetGroup      | Id, LoadBalancer                 |
| ElasticLoadBalancer         | Id                               |
| RDSInstance                 | Id                               |
| RDSClusterInstance          | Id                               |
| RedshiftCluster             | Id                               |
| Lambda                      | Id                               |
| CloudFrontDistribution      | Id                               |
| SQSQueue                    | Id                               |

### Alarm Defaults

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

### Friendly Resource Names

You can set a friendly name which will replace the resource id in the alarm name.
The resource id will still be available in the alarm description.

```yaml
Resources:
  ApplicationTargetGroup:
  - Id: target-group-id
    Loadbalancer: app/application-loadbalancer-id
    Name: webapp
```

### Log Group Metric Filters

Metric filters creates the metric filter and a corresponding alarm.
Cloudwatch NameSpace: `MetricFilters`

AWS [documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html) of pattern syntax

```yaml
Resources:
  LogGroup:
  # Log group name
  - Id: /aws/lambda/myfuntion
    # List of metric filters
    MetricFilters:
    # Name of the cloud watch metric
    - MetricName: MyFunctionErrors
      # search pattern, see aws docs for syntax
      Pattern: error
      # metric to push to cloudwatch. Optional as it defaults to 1
      MetricValue: 1
      
Templates:
  LogGroup:
    # use the MetricName name to override the alarm defaults
    MyFunctionErrors:
      Threshold: 10
```

### Custom Metric Resources

These are also defined under the resources key but more detail is required and differs per group.

#### Http

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
    # boolean tp request a compressed response
    Compressed: true
  - Id: https://www.example.com
    StatusCode: 301
  - Id: https://example.com
    StatusCode: 200
    Ssl: true
    # enables the body regex check
    BodyRegex: 'helloworld'
  - Id: http://www.example.com/images/cat.jpg
    StatusCode: 200
    # md5 hash of the image
    BodyRegex: ae49b4246a89efcb5c639f00a013e812
  - Id: https://api.example.com/user
    StatusCode: 201
    # default method is get but can be overridden to support post/put/head etc
    Method: post
    # specify headers using "key=value key=value"
    Headers: content-type=application/json
    # pass in custom payload for the request
    Payload: '{"name": "john"}'
```

#### InternalHttp

Cloudwatch NameSpace: `InternalHttpCheck`

```yaml
Resources:
  InternalHttp:
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
    # Array of resources defining the http endpoint with the Id: key
    # All the same options as Http including ssl check on the internal endpoint
    - Id: http://api.example.com
```

#### Port

Cloudwatch NameSpace: `PortCheck`

```yaml
Resources:
  Port:
  # Array of resources defining the endpoint with the Id: key and Port: Int
  - Id: api.example.com
    Port: 443
    # can override the default timeout of 120 seconds
    Timeout: 60
```

#### InternalPort

Cloudwatch NameSpace: `InternalPortCheck`

```yaml
Resources:
  InternalPort:
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
    # Array of resources defining the endpoint with the Id: key and Port: Int
    # All the same options as Port
    - Id: api.example.com
      Port: 8080
```

#### DomainExpiry

Cloudwatch NameSpace: `DNS`

```yaml
Resources:
  DomainExpiry:
  # Array of resources defining the domain with the Id: key
  - Id: example.com
```

#### Nrpe

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

#### Sql

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

#### SFTP

CloudWatch Namespace: `SftpCheck`

```yaml
Resources:
  SFTP:
    # sftp endpoint, can accept both ip address or dns endpoint
  - Id: example.com
    # sftp user to test connection with
    User: user
    # optionally set port, defaults to port 22
    Port: 22
    # for added security you can use allowed hosts when creating a 
    # connection to the sftp by supplying the public key of the sftp server.
    # this removes the security risk for man in the middle attacks.
    ServerKey: public-server-key
    # ssm parameter path for the password for the SFTP user. 
    Password: /ssm/path/password
    # ssm parameter path for the private key for the SFTP user
    PrivateKey: /ssm/path/privatekey
    # ssm parameter path for the password for the private key
    PrivateKeyPass: /ssm/path/privatekey/password
    # optionally set a file to check its existence and test the time it takes to get the file
    File: file.txt
    # optionally check for a regex match pattern in the body of the file
    FileRegexMatch: ok
```

#### InternalSFTP

CloudWatch Namespace: `InternalSftpCheck`

```yaml
Resources:
  InternalSFTP:
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
    # Array of sftp hosts with the Id: key defining the host private ip address
    - Id: example.com
      User: user
      Port: 22
      ServerKey: public-server-key
      Password: /ssm/path/password
      PrivateKey: /ssm/path/privatekey
      PrivateKeyPass: /ssm/path/privatekey/password
      File: file.txt
      FileRegexMatch: ok
```

#### TLS

CloudWatch Namespace: `TLSVersionCheck`

```yaml
Resources:
  TLS:
    # endpoint
  - Id: example.com
    # port to check, defaults to 443
    Port: 443
    # list of tls versions to validate against
    # there is a metric for each version with a 0 being no supported and 1 for supported
    # alarm thresholds will have to be adjusted to suit your checking requirements
    # defaults to all versions shown below
    Versions:
      - SSLv2
      - SSLv3
      - TLSv1
      - TLSv1.1
      - TLSv1.2
    # checks and reports the max tls version supported as an int
    # ['SSLv2 => 1', 'SSLv3 => 2', 'TLSv1 => 3','TLSv1.1 => 4', 'TLSv1.2 => 5']
    MaxSupported: '1'
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

## Composite Alarms

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

## Maintenance Mode

CloudWatch alarms can be enabled and disabled to allow maintenance periods without getting alert notifications.
Alarms can be provided to the function the following ways

**Alarm Names**

Alarm names be provided by a space delimited list using the `--alarms` switch.

```bash
cfn-guardian disable-alarms --group alarm-1 alarm-2
cfn-guardian enable-alarms --group alarm-1 alarm-2
```

**Alarm Name Prefix**

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

**Maintenance Groups**

Maintenance groups are defined in the `alarms.yaml` config and creates a logical mapping between alarms.

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

## Severities

Severties are defined in each alarm sing the `AlarmAction` key. There are 4 options `[ Critical, Warning, Task, Informational ]`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/base2services/cfn-guardian.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
