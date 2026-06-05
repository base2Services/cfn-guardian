module CfnGuardian::Resource
  class IoTCore < Base
    
    def default_alarms
      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'ConnectAuthError'
      alarm.metric_name = 'Connect.AuthError'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'ConnectionAuthNError'
      alarm.metric_name = 'Connection.AuthNError'
      alarm.threshold = 10
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'ConnectThrottle'
      alarm.metric_name = 'Connect.Throttle'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'PublishInThrottle'
      alarm.metric_name = 'PublishIn.Throttle'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'PublishInServerError'
      alarm.metric_name = 'PublishIn.ServerError'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'PublishOutThrottle'
      alarm.metric_name = 'PublishOut.Throttle'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'SubscribeThrottle'
      alarm.metric_name = 'Subscribe.Throttle'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::IoTCoreAlarm.new(@resource)
      alarm.name = 'ConnectServerError'
      alarm.metric_name = 'Connect.ServerError'
      alarm.threshold = 0.5
      alarm.period = 300
      alarm.evaluation_periods = 3
      @alarms.push(alarm)
    end
    
  end
end
