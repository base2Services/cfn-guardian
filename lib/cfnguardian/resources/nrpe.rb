require 'digest/md5'
require 'cfnguardian/string'

module CfnGuardian::Resource
  class Nrpe < Base
    
    def initialize(resource)
      super(resource)
      @resource_list = resource['Hosts']
      @environment = resource['Environment']
    end
    
    def default_alarms()
      @resource_list.each do |host|
        host['Commands'].each do |command|
          alarm = CfnGuardian::Models::NrpeAlarm.new(host,@environment)
          alarm.name = "#{command.to_camelcase}Warning"
          alarm.metric_name = command
          alarm.threshold = 0
          alarm.alarm_action = 'Warning'
          @alarms.push(alarm)
          
          alarm = CfnGuardian::Models::NrpeAlarm.new(host,@environment)
          alarm.name = "#{command.to_camelcase}Critical"
          alarm.metric_name = command
          alarm.threshold = 1
          alarm.alarm_action = 'Critical'
          @alarms.push(alarm)
        end
      end
    end
    
    def default_events()
      @resource_list.each do |host|
        host['Commands'].each do |command|
          @events.push(CfnGuardian::Models::NrpeEvent.new(host,@environment,command))
        end
      end
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::NrpeCheck.new(@resource))
    end
    
  end
end
