module CfnGuardian::Resource
  class DMSTask < Base
    
    def default_alarms             
      alarm = CfnGuardian::Models::DMSTaskAlarm.new(@resource)
      alarm.name = 'CDCLatencySourceCritical'
      alarm.metric_name = 'CDCLatencySource'
      alarm.statistic = 'Minimum'
      alarm.threshold = 30
      alarm.evaluation_periods = 10
      alarm.enabled = false
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DMSTaskAlarm.new(@resource)
      alarm.name = 'CDCLatencySourceWarn'
      alarm.metric_name = 'CDCLatencySource'
      alarm.statistic = 'Minimum'
      alarm.threshold = 30
      alarm.evaluation_periods = 1
      alarm.enabled = false
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::DMSTaskAlarm.new(@resource)
      alarm.name = 'CDCLatencyTargetCritical'
      alarm.metric_name = 'CDCLatencyTarget'
      alarm.statistic = 'Minimum'
      alarm.threshold = 30
      alarm.evaluation_periods = 10
      alarm.enabled = false
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::DMSTaskAlarm.new(@resource)
      alarm.name = 'CDCLatencyTargetWarn'
      alarm.metric_name = 'CDCLatencyTarget'
      alarm.statistic = 'Minimum'
      alarm.threshold = 30
      alarm.evaluation_periods = 1
      alarm.enabled = false
      @alarms.push(alarm)
    end
  end
end
