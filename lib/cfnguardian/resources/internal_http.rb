require 'digest/md5'

module CfnGuardian::Resource
  class InternalHttp < Base
    
    def initialize(resource, override_group = nil)
      super(resource, override_group)
      @resource_list = resource['Hosts']
      @environment = resource['Environment']
    end
    
    def default_alarms    
      @resource_list.each do |host|
        alarm = CfnGuardian::Models::InternalHttpAlarm.new(host)
        alarm.name = 'EndpointAvailable'
        alarm.metric_name = 'Available'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::InternalHttpAlarm.new(host)
        alarm.name = 'EndpointStatusCodeMatch'
        alarm.metric_name = 'StatusCodeMatch'
        @alarms.push(alarm)
              
        alarm = CfnGuardian::Models::InternalHttpAlarm.new(host)
        alarm.name = 'EndpointTimeTaken'
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.metric_name = 'TimeTaken'
        alarm.statistic = 'Minimum'
        alarm.threshold = 1000
        alarm.period = 300
        alarm.evaluation_periods = 1
        @alarms.push(alarm)
        
        if host.has_key?('BodyRegex')
          alarm = CfnGuardian::Models::InternalHttpAlarm.new(host)
          alarm.name = 'EndpointBodyRegexMatch'
          alarm.metric_name = 'ResponseBodyRegexMatch'
          @alarms.push(alarm)
        end
        
        if host.has_key?('Ssl') && host['Ssl']
          alarm = CfnGuardian::Models::InternalSslAlarm.new(host)
          alarm.name = 'ExpiresInDaysCritical'
          alarm.metric_name = 'ExpiresInDays'
          alarm.threshold = 5
          @alarms.push(alarm)
          
          alarm = CfnGuardian::Models::InternalSslAlarm.new(host)
          alarm.name = 'ExpiresInDaysTask'
          alarm.metric_name = 'ExpiresInDays'
          alarm.threshold = 30
          @alarms.push(alarm)
        end
      end
    end
    
    def default_events()
      @resource_list.each do |host| 
        @events.push(CfnGuardian::Models::InternalHttpEvent.new(host,@environment))
        if host.has_key?('Ssl') && host['Ssl']
          @events.push(CfnGuardian::Models::InternalSslEvent.new(host,@environment))
        end
      end
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::InternalHttpCheck.new(@resource))
      if @resource_list.any? {|host| host.has_key?('Ssl') && host['Ssl'] }
        @checks.push(CfnGuardian::Models::InternalSslCheck.new(@resource))
      end
    end
    
  end
end
