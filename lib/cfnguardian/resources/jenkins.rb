module CfnGuardian::Resource
    class Jenkins < Base

        def default_alarms
            alarm = CfnGuardian::Models::JenkinsAlarm.new(@resource)
            alarm.name = 'NoSuccess'
            alarm.metric_name = 'Success'
            alarm.statistic = 'Maximum'
            alarm.treat_missing_data = 'breaching'
            alarm.alarm_action = 'Warning'
            alarm.period = 3600
            alarm.comparison_operator = 'LessThanThreshold'
            alarm.threshold = 1
            @alarms.push(alarm)
        end
    end
end