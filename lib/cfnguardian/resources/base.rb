require 'cfnguardian/string'
require 'cfnguardian/models/alarm'
require 'cfnguardian/models/event'
require 'cfnguardian/models/check'

module CfnGuardian::Resource
  class Base
    include Logging
    
    def initialize(resource)
      @resource = resource
      @alarms = []
      @events = []
      @checks = []
    end
    
    def default_alarms()
      return @alarms
    end
    
    def get_alarms(overides={})
      # generate default alarms
      default_alarms()
      
      # loop over each override template for the service
      overides.each do |name,properties|
        
        # disable default alarms
        if [false].include?(properties)
          alarm = find_alarm(name)
          
          if !alarm.nil?
            alarm.enabled = false 
            logger.debug "Disabling alarm '#{name}' for resource #{alarm.resource}"
            next
          end
        end
        
        unless properties.is_a?(Hash)
          if name != 'Inherit'
            logger.warn "Incorrect format for alarm '#{name}'. Should be of type 'Hash', instead got type '#{properties.class}'"
          end
          next
        end
        
        if properties.has_key?('Inherit')
          alarm = find_alarm(properties['Inherit'])
          if !alarm.nil?
            inheritited_alarm = alarm.clone
            alarm.name = name
            properties.each {|attr,value| update_alarm(inheritited_alarm,attr,value)}
            @alarms.push(inheritited_alarm)
          else
            logger.warn "Alarm '#{properties['Inherit']}' doesn't exists and cannot be inherited"
          end
          next
        end
        
        alarm = find_alarm(name)
        
        if alarm.nil?
          alarm = Kernel.const_get("CfnGuardian::Models::#{self.class.to_s.split('::').last}Alarm").new(properties)
        end
        
        if alarm.name.nil?
          alarm.name = name
        end
        
        properties.each {|attr,value| update_alarm(alarm,attr,value)}
        @alarms.push(alarm)
        
      end
      
      return @alarms.select{|a| a.enabled}.map {|a| a.to_h}
    end
    
    def default_events()
      return @events
    end
    
    def get_events()
      default_events()
      return @events.select{|e| e.enabled}.map {|e| e.to_h}
    end
    
    def default_checks()
      return @checks
    end
    
    def get_checks()
      default_checks()
      return @checks.map {|c| c.to_h}
    end
    
    def get_cost()
      return @alarms.length * 0.10
    end
    
    private
    
    def find_alarm(name)
      @alarms.detect {|alarm| alarm.name == name}
    end
    
    def update_alarm(alarm,attr,value)
      begin
        alarm.send("#{attr.to_underscore}=",value)
      rescue NoMethodError => e
        if !e.message.match?(/inherit/)
          logger.warn "Unknown key '#{attr}' for #{alarm.resource} alarm #{alarm.name}"
        end
      end
    end
    
  end
end