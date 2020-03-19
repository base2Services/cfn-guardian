require 'cfnguardian/string'
require 'digest/md5'

module CfnGuardian
  module Models
    class MetricFilter
      
      attr_reader :type,
        :metric_namespace,
        :name
      attr_accessor :log_group,
        :pattern,
        :metric_value,
        :metric_name
      
      def initialize(log_group,filter)
        @type = 'MetricFilter'
        @name = Digest::MD5.hexdigest(log_group + filter['MetricName'])
        @log_group = log_group
        @pattern = filter['Pattern']
        @metric_value = filter.fetch('MetricValue', '1').to_s
        @metric_name = filter['MetricName']
        @metric_namespace = "MetricFilters"
      end
      
    end
  end
end