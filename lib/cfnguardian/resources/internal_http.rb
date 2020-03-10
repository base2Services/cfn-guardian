require 'digest/md5'

module CfnGuardian::Resource
  class InternalHttp < Base
    
    def initialize(resource)
      super(resource)
      @resource_list = resource['Hosts']
      @environment = resource['Environment']
    end
    
    def default_alarms    
      @resource_list.each do |host|
        alarm = CfnGuardian::Models::HttpAlarm.new(host)
        alarm.name = 'EndpointAvailable'
        alarm.metric_name = 'Available'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::HttpAlarm.new(host)
        alarm.name = 'EndpointStatusCodeMatch'
        alarm.metric_name = 'StatusCodeMatch'
        @alarms.push(alarm)
              
        alarm = CfnGuardian::Models::HttpAlarm.new(host)
        alarm.name = 'EndpointTimeTaken'
        alarm.metric_name = 'TimeTaken'
        alarm.statistic = 'Minimum'
        alarm.threshold = 1000
        alarm.period = 300
        alarm.evaluation_periods = 1
        @alarms.push(alarm)
        
        if @resource.has_key?('BodyRegex')
          alarm = CfnGuardian::Models::HttpAlarm.new(host)
          alarm.name = 'EndpointBodyRegexMatch'
          alarm.metric_name = 'ResponseBodyRegexMatch'
          @alarms.push(alarm)
        end
      end
    end
    
    def default_events()
      @resource_list.each {|host| @events.push(CfnGuardian::Models::InternalHttpEvent.new(host))}
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::InternalHttpCheck.new(@resource))
    end
    
  end
end
