require 'digest/md5'

module CfnGuardian::Resource
  class Http < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::HttpAlarm.new(@resource)
      alarm.name = 'EndpointAvailable'
      alarm.metric_name = 'Available'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::HttpAlarm.new(@resource)
      alarm.name = 'EndpointStatusCodeMatch'
      alarm.metric_name = 'StatusCodeMatch'
      @alarms.push(alarm)
            
      alarm = CfnGuardian::Models::HttpAlarm.new(@resource)
      alarm.name = 'EndpointTimeTaken'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.metric_name = 'TimeTaken'
      alarm.statistic = 'Minimum'
      alarm.threshold = 1000
      alarm.period = 300
      alarm.evaluation_periods = 1
      @alarms.push(alarm)
      
      if @resource.has_key?('BodyRegex')
        alarm = CfnGuardian::Models::HttpAlarm.new(@resource)
        alarm.name = 'EndpointBodyRegexMatch'
        alarm.metric_name = 'ResponseBodyRegexMatch'
        @alarms.push(alarm)
      end
      
      if @resource.has_key?('Ssl') && @resource['Ssl']
        alarm = CfnGuardian::Models::SslAlarm.new(@resource)
        alarm.name = 'ExpiresInDaysCritical'
        alarm.metric_name = 'ExpiresInDays'
        alarm.threshold = 5
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::SslAlarm.new(@resource)
        alarm.name = 'ExpiresInDaysTask'
        alarm.metric_name = 'ExpiresInDays'
        alarm.alarm_action = 'Task'
        alarm.threshold = 30
        @alarms.push(alarm)
      end
    end
    
    def default_events()
      @events.push(CfnGuardian::Models::HttpEvent.new(@resource))
      if @resource.has_key?('Ssl') && @resource['Ssl']
        @events.push(CfnGuardian::Models::SslEvent.new(@resource))
      end
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::HttpCheck.new(@resource))
      if @resource.has_key?('Ssl') && @resource['Ssl']
        @checks.push(CfnGuardian::Models::SslCheck.new(@resource))
      end
    end
    
  end
end
