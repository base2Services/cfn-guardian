module CfnGuardian::Resource
  class LogGroup < Base
    
    def initialize(resource, override_group = nil)
      super(resource, override_group)
      @resource_list = resource['MetricFilters']
    end
    
    def default_alarms()
      @resource_list.each do |filter|
        alarm = CfnGuardian::Models::LogGroupAlarm.new(@resource)
        alarm.name = filter['MetricName']
        alarm.metric_name = filter['MetricName']
        @alarms.push(alarm)
      end
    end
    
    def default_metric_filters()
      @resource_list.each do |filter|
        metric_filter = CfnGuardian::Models::MetricFilter.new(@resource['Id'],filter)
        @metric_filters.push(metric_filter)
      end
    end
    
  end
end