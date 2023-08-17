# CfnGuardian

[Documentation](docs/overview.md)

CfnGuardian is a AWS monitoring tool with a few capabilities:

- creates cloudwatch alarms through cloudformation based upon resources defined in a YAML config
- alerting through SNS using 4 levels of severity [ Critical, Warning, Task, Informational ]  
- has a standard set of default alarms across many AWS resources
- creates cloudwatch log metric filters with default alarms
- creates specfic aws events with sns targets
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
- ACM Certificates
- AmazonMq(RabbitMQ and ActiveMQ)
- ApiGateway
- Application Targetgroups
- Network TargetGroups
- AutoScalingGroups
- CloudFront Distributions
- DocumentDB Clusters
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
- ElasticSearch