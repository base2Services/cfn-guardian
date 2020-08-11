# SFTP

The sftp check produces 5 different metrics that alarms can be created from.

1. `Available` whether a connection could be made in timely manner, indicating problems with network, DNS lookup or server timeout.
2. `ConnectionTime` time taken to connect to the sftp server, reported in milliseconds.
3. `FileExists` checks the existence of the specified file in the location specified. 
4. `FileGetTime` time taken to download the file specified.
5. `FileBodyMatch` body of the file specified matches regex provided.

[aws-lambda-sftp-check](https://github.com/base2Services/aws-lambda-sftp-check)

## Public SFTP Check

The public sftp check executes the check against a public endpoint.

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
    FileBodyMatch: ok
```

## Private SFTP Check

Private sftp check should be used when running the check against a private sftp endpoint or a public sftp point that requies whitelisting. Whitelisting can be achieved by putting the sftp check in a private subnet and hitting the endpoint through a NAT gateway, whitelisting the NAT gateway's IP on the sftp security group.

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
      FileBodyMatch: ok
```