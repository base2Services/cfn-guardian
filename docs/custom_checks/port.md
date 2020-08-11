# Port

The port check checks a TCP port connection is established on a specified port within the timeout.

## Public Port Check

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

## Private Port Check

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