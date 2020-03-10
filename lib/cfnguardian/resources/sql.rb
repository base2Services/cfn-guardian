require 'digest/md5'
require 'cfnguardian/string'

module CfnGuardian::Resource
  class Sql < Base
    
    def initialize(resource)
      super(resource)
      @resource_list = resource['Hosts']
      @environment = resource['Environment']
    end
    
    def default_alarms()
      @resource_list.each do |host|
        host['Queries'].each do |query|
          alarm = CfnGuardian::Models::SqlAlarm.new(host)
          alarm.name = query['MetricName']
          alarm.metric_name = query['MetricName']
          @alarms.push(alarm)
        end
      end
    end
    
    def default_events()
      @resource_list.each do |host|
        host['Queries'].each do |query|
          @events.push(CfnGuardian::Models::SqlEvent.new(host,query['Query'],@environment))
        end
      end
    end
    
    def default_checks()
      @checks.push(CfnGuardian::Models::SqlCheck.new(@resource))
    end
    
  end
end
