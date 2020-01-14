module CfnGuardian
  module Resource
    class ElastiCacheReplicationGroup < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::ElastiCacheReplicationGroupAlarm.new(@resource)
        alarm.name = 'FreeableMemoryWarning'
        alarm.metric_name = 'FreeableMemory'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.threshold = 100000000
        alarm.evaluation_periods = 10
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ElastiCacheReplicationGroupAlarm.new(@resource)
        alarm.name = 'CPUUtilizationWarning'
        alarm.metric_name = 'CPUUtilization'
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.statistic = 'Minimum'
        alarm.threshold = 75
        alarm.evaluation_periods = 10
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ElastiCacheReplicationGroupAlarm.new(@resource)
        alarm.name = 'CurrentConnectionsTask'
        alarm.metric_name = 'CurrConnections'
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.threshold = 50000
        alarm.evaluation_periods = 10
        alarm.alarm_action = 'Task'
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::ElastiCacheReplicationGroupAlarm.new(@resource)
        alarm.name = 'CurrentConnectionsCritical'
        alarm.metric_name = 'CurrConnections'
        alarm.comparison_operator = 'GreaterThanThreshold'
        alarm.threshold = 60000
        alarm.evaluation_periods = 10
        @alarms.push(alarm)
      end
      
    end
  end
end
