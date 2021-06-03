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

        alarm = CfnGuardian::Models::ElasticFileSystemAlarm.new(@resource)
        alarm.name = 'BurstCreditBalanceLow'
        alarm.metric_name = 'BurstCreditBalance'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'Minimum'
        alarm.threshold = 1000000000000
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.datapoints_to_alarm = 5
        @alarms.push(alarm)
      end
    end
  end
end
