# Nrpe

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