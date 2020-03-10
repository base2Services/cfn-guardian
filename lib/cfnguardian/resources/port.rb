module CfnGuardian::Resource
  class Port < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::PortAlarm.new(@resource)
      alarm.name = 'EndpointAvailable'
      alarm.metric_name = 'Available'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::PortAlarm.new(@resource)
      alarm.name = 'EndpointTimeTaken'
      alarm.metric_name = 'TimeTaken'
      @alarms.push(alarm)
    end
    
    def default_events()
      @events.push(CfnGuardian::Models::PortEvent.new(@resource))
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::PortCheck.new(@resource))
    end
    
  end
end