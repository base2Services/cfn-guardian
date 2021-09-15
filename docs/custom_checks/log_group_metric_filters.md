# Log Group Metric Filters

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
      Pattern: 'error'
      # metric to push to cloudwatch. Optional as it defaults to 1
      MetricValue: 1
  - Id: /prod/custom/app
    # List of metric filters
    MetricFilters:
    # Name of the cloud watch metric
    - MetricName: MyAppErrors
      # search pattern, see aws docs for syntax
      # note; any non-alphanumeric characters have to be wrapped in double quotes WITHIN single quotes
      Pattern: '"Connection to ssl://mail.google.com:465 Timed Out"'
      # metric to push to cloudwatch. Optional as it defaults to 1
      MetricValue: 1      

Templates:
  LogGroup:
    # use the MetricName name to override the alarm defaults
    MyFunctionErrors:
      Threshold: 10
```