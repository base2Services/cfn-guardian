module CfnGuardian::Resource
  class TLS < Base
    
    def default_alarms
      
      versions = @resource.fetch('Versions',['SSLv2','SSLv3','TLSv1','TLSv1.1','TLSv1.2'])
      
      if versions.include? "SSLv2"
        alarm = CfnGuardian::Models::TLSAlarm.new(@resource)
        alarm.name = "TLSVersionSSLv2"
        alarm.metric_name = "SSLv2"
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.threshold = 0
        @alarms.push(alarm)
      end
      
      if versions.include? "SSLv3"
        alarm = CfnGuardian::Models::TLSAlarm.new(@resource)
        alarm.name = "TLSVersionSSLv3"
        alarm.metric_name = "SSLv3"
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.threshold = 0
        @alarms.push(alarm)
      end
      
      if versions.include? "SSLv3"
        alarm = CfnGuardian::Models::TLSAlarm.new(@resource)
        alarm.name = "TLSVersionTLSv1"
        alarm.metric_name = "TLSv1"
        @alarms.push(alarm)
      end
      
      if versions.include? "SSLv3"
        alarm = CfnGuardian::Models::TLSAlarm.new(@resource)
        alarm.name = "TLSVersionTLSv1.1"
        alarm.metric_name = "TLSv1.1"
        @alarms.push(alarm)
      end
      
      if versions.include? "SSLv3"
        alarm = CfnGuardian::Models::TLSAlarm.new(@resource)
        alarm.name = "TLSVersionTLSv1.2"
        alarm.metric_name = "TLSv1.2"
        @alarms.push(alarm)
      end
    
      if @resource.has_key?('CheckMax')
        alarm = CfnGuardian::Models::TLSAlarm.new(@resource)
        alarm.name = "TLSVersionMax"
        alarm.metric_name = 'MaxVersion'
        alarm.threshold = 3
        alarm.evaluation_periods = 2
        @alarms.push(alarm)
      end
    end
    
    def default_events
      @events.push(CfnGuardian::Models::TLSEvent.new(@resource))
    end
    
    def default_checks
      @checks.push(CfnGuardian::Models::TLSCheck.new(@resource))
    end
    
  end
end