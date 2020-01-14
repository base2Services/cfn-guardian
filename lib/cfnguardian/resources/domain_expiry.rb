require 'digest/md5'

module CfnGuardian::Resource
  class DomainExpiry < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::DomainExpiryAlarm.new(@resource)
      alarm.name = 'ExpiresInDaysCritical'
      alarm.metric_name = 'ExpiresInDays'
      alarm.threshold = 7
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::DomainExpiryAlarm.new(@resource)
      alarm.name = 'ExpiresInDaysWarning'
      alarm.metric_name = 'ExpiresInDays'
      alarm.threshold = 30
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
    end
    
    def default_events()
      @events.push(CfnGuardian::Models::DomainExpiryEvent.new(@resource))
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::DomainExpiryCheck.new(@resource))
    end
    
  end
end
