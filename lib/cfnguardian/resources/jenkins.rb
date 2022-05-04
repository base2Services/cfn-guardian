module CfnGuardian::Resource
    class Jenkins < Base
        def default_alarms
            # evaluate this alarm every hour but only alert if there is no data point after 25 hours
            alarm = CfnGuardian::Models::JenkinsAlarm.new(@resource)
            alarm.name = 'HealthyAgent'
            alarm.metric_name = 'HealthyAgent'
            alarm.statistic = 'Maximum'
            alarm.treat_missing_data = 'breaching'
            alarm.alarm_action = 'Warning'
            alarm.period = 3600 # 1 hour
            alarm.evaluation_periods = 24 # 24 hours
            alarm.comparison_operator = 'LessThanThreshold'
            alarm.threshold = 1
            @alarms.push(alarm)
        end
    end
end