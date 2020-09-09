# Azure File Check

CloudWatch Namespace: `FileAgeCheck`

```yaml
Resources:
  AzureFile:
    # Storage account
  - Id: us187fnakrap
    # Container within storage account
    Container: mybackups
    # SSM Param within the AWS account which contains the storage account connection string
    ConnectionString: /azurefilecheck/test/connection_string
    # List of search objects
    Search:
      -
        # Prefix used to filter returned items in blob storage
        PREFIX: file123
        # File identifer to perform age check on
        REGEX: .log
        # Oldest expected file age in seconds
        OLDEST: 300
      -
        PREFIX: file456
        REGEX: .bak
        OLDEST: 86400
```