# Guardian CLI Commands

Guardian deployments are managed by AWS codebuild and AWS codepipeline but there are some useful commands to help debug an issue.

## Install the cli

```ruby
gem install cfn-guardian
```

## CLI Help

```sh
Commands:
  cfn-guardian --version, -v               # print the version
  cfn-guardian compile c, --config=CONFIG  # Generate monitoring CloudFormation templates
  cfn-guardian deploy c, --config=CONFIG   # Generates and deploys monitoring CloudFormation templates
  cfn-guardian disable-alarms              # Disable cloudwatch alarm notifications
  cfn-guardian enable-alarms               # Enable cloudwatch alarm notifications
  cfn-guardian help [COMMAND]              # Describe available commands or one specific command
  cfn-guardian show-alarms                 # Shows alarm settings
  cfn-guardian show-config-history         # Shows the last 10 commits made to the codecommit repo
  cfn-guardian show-drift                  # Cloudformation drift detection
  cfn-guardian show-history                # Shows alarm history for the last 7 days
  cfn-guardian show-pipeline               # Shows the current state of the AWS code pipeline
  cfn-guardian show-state                  # Shows alarm state in cloudwatch

Options:
  [--debug], [--no-debug]  # enable debug logging
```

## Alarm Debugging

### show-alarms

Displays the configured settings for each alarm. Can be filtered by resource group and alarm name. Defaults to show all configured alarms.
Alarms can be filtered using the `--filter` switch providing multiple key:values witch uses the and operator.

```bash
Usage:
  cfn-guardian show-alarms

Options:
  c, [--config=CONFIG]               # yaml config file
      [--defaults], [--no-defaults]  # display default alarms and properties
  r, [--region=REGION]               # set the AWS region
      [--filter=key:value]           # filter the displayed alarms by [group, resource-id, alarm, stack-id, topic, maintenance-group]
      [--compare], [--no-compare]    # compare config to deployed alarms
      [--debug], [--no-debug]        # enable debug logging
```

### show-history

Displays the alarm state or config history for the last 7 days. Alarms can be described in 2 different ways:

1. Using the config to describe the alarms and filter via the group, alarm and resource id. 
2. Supplying a list of alarm names with the `--alarm-names` option.

*NOTE: Options 2 may find alarms not in the guardian stack.*

```bash
Usage:
  cfn-guardian show-history

Options:
  r, [--region=REGION]               # set the AWS region
      [--alarm-names=one two three]  # list of cloudwatch alarm names
  t, [--type=TYPE]                   # filter by alarm state
                                     # Default: state
                                     # Possible values: state, config
      [--alarm-prefix=ALARM_PREFIX]  # cloudwatch alarm name prefix
                                     # Default: guardian
      [--filter=key:value]           # filter the displayed alarms by [group, resource-id, alarm, stack-id]
      [--debug], [--no-debug]        # enable debug logging
```

### show-state

Displays the state of the deployed CloudWatch alarms. Alarms can be filtered using the `--filter` switch providing multiple key:values witch uses the and operator.
Alarm can also be filtered using the `--alarms-prefix` to only list alarms that begin with the provided string.

```bash
Usage:
  cfn-guardian show-state

Options:
  r, [--region=REGION]               # set the AWS region
  s, [--state=STATE]                 # filter by alarm state
                                     # Possible values: OK, ALARM, INSUFFICIENT_DATA
      [--alarm-names=one two three]  # list of cloudwatch alarm names
      [--alarm-prefix=ALARM_PREFIX]  # cloudwatch alarm name prefix
                                     # Default: guardian
      [--filter=key:value]           # filter the displayed alarms by [group, resource-id, alarm, stack-id, topic, maintenance-group]
      [--debug], [--no-debug]        # enable debug logging
```

### show-drift

Displays any Cloudformation drift detection in the CloudWatch alarms from the deployed stacks. Useful for detecting manual changes to an alarm.

```bash
Usage:
  cfn-guardian show-drift

Options:
  s, [--stack-name=STACK_NAME]  # set the Cloudformation stack name
                                # Default: guardian
      [--debug], [--no-debug]   # enable debug logging
```

## Enabling and Disabling Alarms

### Disable Alarms

Disable cloudwatch alarm notifications for a maintenance group or for specific alarms. See [maintenace groups](maintenance_mode.md) docs for more information.

```yaml
Usage:
  cfn-guardian disable-alarms

Options:
  r, [--region=REGION]               # set the AWS region
  g, [--group=GROUP]                 # name of the maintenance group defined in the config
      [--alarm-prefix=ALARM_PREFIX]  # cloud watch alarm name prefix
      [--alarms=one two three]       # List of cloudwatch alarm names
      [--debug], [--no-debug]        # enable debug logging
```

### Enable Alarms

Enable cloudwatch alarm notifications for a maintenance group or for specific alarms. Once alarms are enable the state is set back to OK to re send notifications of any failed alarms.

```yaml
Usage:
  cfn-guardian enable-alarms

Options:
  r, [--region=REGION]               # set the AWS region
  g, [--group=GROUP]                 # name of the maintenance group defined in the config
      [--alarm-prefix=ALARM_PREFIX]  # cloud watch alarm name prefix
      [--alarms=one two three]       # List of cloudwatch alarm names
      [--debug], [--no-debug]        # enable debug logging
```

## Cloudformation Stack

### compile

Generates CloudFormation templates from the alarm configuration and output to the out/ directory. Useful if you want to debug a config issue locally.

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

### deploy

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
