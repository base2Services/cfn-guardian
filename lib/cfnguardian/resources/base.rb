require 'cfnguardian/string'
require 'cfnguardian/cloudwatch'
require 'cfnguardian/models/alarm'
require 'cfnguardian/models/event'
require 'cfnguardian/models/check'
require 'cfnguardian/models/metric_filter'
require 'cfnguardian/models/event_subscription'

module CfnGuardian::Resource
  class Base
    include Logging
    
    def initialize(resource, override_group = nil)
      @resource = resource
      @override_group = override_group
      @alarms = []
      @events = []
      @checks = []
      @metric_filters = []
      @event_subscriptions = []
    end
    
    # Overidden by inheritted classes to define default alarms
    def default_alarms()
      return @alarms
    end
    
    def get_alarms(group,overides={})
      # generate default alarms
      default_alarms()

      # override any group properties
      group_overrides = overides.has_key?('GroupOverrides') ? overides['GroupOverrides'] : {}
      overides.delete('GroupOverrides')
      if group_overrides.any?
        @alarms.each do |alarm|
          logger.debug("overriding #{alarm.name} alarm properties for resource #{alarm.resource_id} in resource group #{group} via group overrides") 
          group_overrides.each {|attr,value| update_object(alarm,attr,value)}
        end
      end

      # loop over each override template for the service
      overides.each do |name,properties|       
        # disable default alarms
        if [false].include?(properties)
          alarms = find_alarms(name)
          
          if !alarms.nil?
            alarms.each do |alarm| 
              alarm.enabled = false
              logger.info "disabling alarm '#{name}' for resource #{alarm.resource_id}"
            end
            next
          end
        end

        # continue if the override is in the incorrect format
        unless properties.is_a?(Hash)
          if name != 'Inherit'
            logger.warn "incorrect format for alarm '#{name}'. Should be of type 'Hash', instead got type '#{properties.group}'"
          end
          next
        end

        properties.merge!(group_overrides)

        # Create a new alarm inheriting the defaults of an existing alarm
        if properties.has_key?('Inherit')
          alarm = find_alarm(properties['Inherit'])
          if !alarm.nil?
            logger.debug("creating new alarm #{name} for alarm group #{self.class.to_s.split('::').last} inheriting properties from alarm #{properties['Inherit']}")
            inheritited_alarm = alarm.clone
            alarm.name = name
            properties.each {|attr,value| update_object(inheritited_alarm,attr,value)}
            @alarms.push(inheritited_alarm)
          else
            logger.warn "alarm '#{properties['Inherit']}' doesn't exists and cannot be inherited"
          end
          next
        end
        
        alarms = find_alarms(name)

        if alarms.empty?
          # if the alarm doesn't exist and it's not being inherited from another alarm create a new alarm
          resources = @resource.has_key?('Hosts') ? @resource['Hosts'] : [@resource]
          resources.each do |res|
            alarm = Kernel.const_get("CfnGuardian::Models::#{self.class.to_s.split('::').last}Alarm").new(res)
            properties.each {|attr,value| update_object(alarm,attr,value)}
            alarm.name = name
            logger.debug("created new alarm #{alarm.name} for resource #{alarm.resource_id} in resource group #{group}")
            @alarms.push(alarm)
          end
        else
          # if there is an existing alarm update the properties
          alarms.each do |alarm|
            logger.debug("overriding #{alarm.name} alarm properties for resource #{alarm.resource_id} in resource group #{group} via alarm overrides") 
            properties.each {|attr,value| update_object(alarm,attr,value)}
          end
        end
      end
      
      unless @override_group.nil?
        @alarms.each {|a| a.group = @override_group}
      end
      
      # String interpolation for alarm dimensions
      @alarms.each do |alarm|
        next if alarm.dimensions.nil?
        alarm.dimensions.each do |k,v|
          if v.match?(/^\${Resource::.*[A-Za-z]}$/)
            resource_key = v.tr('${}', '').split('Resource::').last
            if @resource.has_key?(resource_key)
              logger.debug "overriding alarm #{alarm.name} dimension key '#{k}' with value '#{@resource[resource_key]}'" 
              alarm.dimensions[k] = @resource[resource_key]
            end
          end
        end
      end

      return @alarms.select{|a| a.enabled}
    end
    
    # Overidden by inheritted classes to define default events
    def default_events()
      return @events
    end
    
    def get_events()
      default_events()
      return @events.select{|e| e.enabled}
    end
    
    # Overidden by inheritted classes to define default checks
    def default_checks()
      return @checks
    end
    
    def get_checks()
      default_checks()
      return @checks
    end
    
    # Overidden by inheritted classes to define default checks
    def default_metric_filters()
      return @metric_filters
    end
    
    def get_metric_filters()
      default_metric_filters()
      return @metric_filters
    end

    # Overidden by inheritted classes to define default checks
    def default_event_subscriptions()
      return @event_subscriptions
    end
    
    def get_event_subscriptions(group, overides)
      # generate defailt event subscriptions
      default_event_subscriptions()

      # overide the defaults
      overides.each do |name, properties|
        event_subscription = find_event_subscriptions(name)

        # disbable the event subscription if the value is false
        if [false].include?(properties)
          unless event_subscription.nil?
            event_subscription.enabled = false
            logger.info "Disabling event subscription #{name} for #{group} #{event_subscription.resource_id}"
          end

          next
        end

        # ignore all properties not in a proper format
        next unless properties.is_a?(Hash) 

        # Create a new event subscription by inheriting an existing one
        if properties.has_key?('Inherit')
          inherit_event_subscription = find_event_subscriptions(properties['Inherit'])
          
          if inherit_event_subscription.nil?
            logger.warn "Unable to create #{topic} RDSEventSubscription by inheriting #{properties['Inherit']} as it cannot be found"
            next
          end

          event_subscription = inherit_event_subscription.clone
          event_subscription.enabled = true
          event_subscription.name = name
          @event_subscriptions.push(event_subscription) 
          logger.debug "Inheriting RDSEventSubscription #{properties['Inherit']}"
        end

        if event_subscription.nil?
          event_subscription = Kernel.const_get("CfnGuardian::Models::#{self.class.to_s.split('::').last}EventSubscription").new(@resource)
          event_subscription.name = name
          @event_subscriptions.push(event_subscription) 
        end

        properties.each {|attr,value| update_object(event_subscription,attr,value)}
      end

      return @event_subscriptions.select {|es| es.enabled }
    end
    
    def get_cost()
      return @alarms.length * 0.10
    end
    
    private
    
    def find_alarm(name)
      @alarms.detect {|alarm| alarm.name == name}
    end

    def find_alarms(name)
      @alarms.find_all {|alarm| alarm.name == name}
    end

    def find_event_subscriptions(name)
      @event_subscriptions.detect {|es| es.name == name}
    end

    def update_object(obj,attr,value)
      logger.debug("overriding #{obj.type} property '#{attr}' with value #{value} for resource id: #{obj.resource_id}")
      begin
        obj.send("#{attr.to_underscore}=",value.clone)
      rescue NoMethodError => e
        if !e.message.match?(/inherit/)
          logger.warn "Unknown property '#{attr}' for type: #{obj.type} and resource id: #{obj.resource_id}"
        end
      end
    end
    
  end
end