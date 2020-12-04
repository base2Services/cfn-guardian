## Dimension Variables

variables can be used to reference resource group values such as the resource Id within the dimensions section of an alarm template.

For example here we are creating an alarm for a disk usage metric for a group of EC2 instances.

```yaml
Templates:
  Ec2Instance:
    LowDiskSpaceRootVolume:
      Namespace: CWAgent
      MetricName: DiskSpaceUsedPercent
      Dimensions:
        path: '/'
        # Reference the resource Id from the resource group
        host: ${Resource::Id}
        device: 'xvda1'
        fstype: 'ext4'
      Statistic: Maximum
      Threshold: 85  
      Period: 60
      EvaluationPeriods: 1
      TreatMissingData: breaching

Resources:
  Ec2Instance:
    - Id: i-12345678
    - Id: i-abcdefgh
```

custom variables can be referenced if you have different dimensions for each resource. using the example above, you may have different file system types on each instance. 

```yaml
Templates:
  Ec2Instance:
    LowDiskSpaceRootVolume:
      Namespace: CWAgent
      MetricName: DiskSpaceUsedPercent
      Dimensions:
        path: '/'
        # Reference the resource Id from the resource group
        host: ${Resource::Id}
        device: 'xvda1'
        # Reference the resource FileSystemType from the resource group
        fstype: ${Resource::FileSystemType}
      Statistic: Maximum
      Threshold: 85  
      Period: 60
      EvaluationPeriods: 1
      TreatMissingData: breaching

Resources:
  Ec2Instance:
    - Id: i-12345678
      FileSystemType: ext4
    - Id: i-abcdefgh
      FileSystemType: ext4
```