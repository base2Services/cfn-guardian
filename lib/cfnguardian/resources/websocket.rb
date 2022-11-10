require 'digest/md5'

module CfnGuardian::Resource
  class WebSocket < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::WebSocketAlarm.new(@resource)
      alarm.name = 'EndpointAvailable'
      alarm.metric_name = 'Available'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::WebSocketAlarm.new(@resource)
      alarm.name = 'EndpointTimeTaken'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.metric_name = 'TimeTaken'
      alarm.statistic = 'Minimum'
      alarm.threshold = 5000
      alarm.period = 300
      alarm.evaluation_periods = 1
      @alarms.push(alarm)
    end
    
    def default_events()
      @events.push(CfnGuardian::Models::WebSocketEvent.new(@resource))
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::WebSocketCheck.new(@resource))
    end
    
  end
end
