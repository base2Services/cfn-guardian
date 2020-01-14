module CfnGuardian
  module Resource
    class ElasticFileSystem < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::ElasticFileSystemAlarm.new(@resource)
        alarm.name = 'PercentIOLimitHigh'
        alarm.metric_name = 'PercentIOLimit'
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.threshold = 90
        alarm.evaluation_periods = 5
        alarm.statistic = 'Minimum'
        @alarms.push(alarm)
      end
    end
  end
end
