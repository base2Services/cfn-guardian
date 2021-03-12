module CfnGuardian::Resource
  class StepFunctions < Base
      
    def default_alarms    
      alarm = CfnGuardian::Models::StepFunctionsAlarm.new(@resource)
      alarm.name = 'ExecutionsFailed'
      alarm.metric_name = 'ExecutionsFailed'
      alarm.threshold = 1
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::StepFunctionsAlarm.new(@resource)
      alarm.name = 'ExecutionsTimedOut'
      alarm.metric_name = 'ExecutionsTimedOut'
      alarm.threshold = 1
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::StepFunctionsAlarm.new(@resource)
      alarm.name = 'ExecutionThrottled'
      alarm.metric_name = 'ExecutionThrottled'
      alarm.threshold = 1
      alarm.evaluation_periods = 5
      alarm.alarm_action = 'Warning'
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::StepFunctionsAlarm.new(@resource)
      alarm.name = 'ExecutionTime'
      alarm.metric_name = 'ExecutionTime'
      alarm.threshold = 60
      alarm.evaluation_periods = 5
      alarm.alarm_action = 'Warning'
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
      
  end
end
