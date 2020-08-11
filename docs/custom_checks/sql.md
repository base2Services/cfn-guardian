# Sql

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
