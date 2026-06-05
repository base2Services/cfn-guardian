module CfnGuardian::Resource
  class IoTRule < Base
    
    def default_alarms
      alarm = CfnGuardian::Models::IoTRuleAlarm.new(@resource)
      alarm.name = 'RuleActionFailure'
      alarm.metric_name = 'Failure'
      alarm.threshold = 0.5
      alarm.period = 60
      alarm.evaluation_periods = 5
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTRuleAlarm.new(@resource)
      alarm.name = 'RuleParseError'
      alarm.metric_name = 'ParseError'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTRuleAlarm.new(@resource)
      alarm.name = 'RuleExecutionThrottled'
      alarm.metric_name = 'RuleExecutionThrottled'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTRuleAlarm.new(@resource)
      alarm.enabled = false
      alarm.name = 'RuleTopicMatch'
      alarm.metric_name = 'TopicMatch'
      alarm.threshold = 0
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.comparison_operator = 'LessThanOrEqualToThreshold'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
    end
    
  end
end
