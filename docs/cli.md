# Guardian CLI Commands

Guardian deployments are managed by AWS codebuild and AWS codepipeline but there are some useful commands to help debug an issue.

## Install the cli

```ruby
gem install cfn-guardian
```

## show-alarms

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

## show-history

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

## show-state

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

## show-drift

Displays any Cloudformation drift detection in the CloudWatch alarms from the deployed stacks. Useful for detecting manual changes to an alarm.

```bash
Usage:
  cfn-guardian show-drift

Options:
  s, [--stack-name=STACK_NAME]  # set the Cloudformation stack name
                                # Default: guardian
      [--debug], [--no-debug]   # enable debug logging
```

## compile

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

## deploy

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
