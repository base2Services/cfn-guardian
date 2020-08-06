module CfnGuardian::Resource
  class InternalSFTP < Base
    
    def initialize(resource, override_group = nil)
      super(resource, override_group)
      @resource_list = resource['Hosts']
      @environment = resource['Environment']
    end
    
    def default_alarms
      @resource_list.each do |host|
        alarm = CfnGuardian::Models::InternalSFTPAlarm.new(host)
        alarm.name = 'Available'
        alarm.metric_name = 'Available'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::InternalSFTPAlarm.new(host)
        alarm.name = 'ConnectionTime'
        alarm.metric_name = 'ConnectionTime'
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.statistic = 'Minimum'
        alarm.threshold = 1000
        @alarms.push(alarm)
        
        if host.has_key?('File')
          alarm = CfnGuardian::Models::InternalSFTPAlarm.new(host)
          alarm.name = 'FileExists'
          alarm.metric_name = 'FileExists'
          @alarms.push(alarm)
        
          alarm = CfnGuardian::Models::InternalSFTPAlarm.new(host)
          alarm.name = 'FileGetTime'
          alarm.metric_name = 'FileGetTime'
          alarm.comparison_operator = 'GreaterThanThreshold'
          alarm.statistic = 'Minimum'
          alarm.threshold = 1000
          @alarms.push(alarm)
          
          if host.has_key?('FileRegexMatch')
            alarm = CfnGuardian::Models::InternalSFTPAlarm.new(host)
            alarm.name = 'FileBodyMatch'
            alarm.metric_name = 'FileBodyMatch'
            @alarms.push(alarm)
          end
        end
      end
    end
    
    def default_events
      @resource_list.each {|host| @events.push(CfnGuardian::Models::InternalSFTPEvent.new(host,@environment)) }
    end
    
    def default_checks
      @checks.push(CfnGuardian::Models::InternalSFTPCheck.new(@resource))
    end
    
  end
end