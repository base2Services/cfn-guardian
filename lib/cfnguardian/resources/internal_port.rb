module CfnGuardian::Resource
  class InternalPort < Base
    
    def initialize(resource)
      super(resource)
      @resource_list = resource['Hosts']
      @environment = resource['Environment']
    end
    
    def default_alarms    
      @resource_list.each do |host|
        alarm = CfnGuardian::Models::PortAlarm.new(host)
        alarm.name = 'EndpointAvailable'
        alarm.metric_name = 'Available'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::PortAlarm.new(host)
        alarm.name = 'EndpointTimeTaken'
        alarm.metric_name = 'TimeTaken'
        @alarms.push(alarm)
      end
    end
    
    def default_events()
      @resource_list.each {|host| @events.push(CfnGuardian::Models::InternalPortEvent.new(host))}
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::InternalPortCheck.new(@resource))
    end
    
  end
end
