module CfnGuardian::Resource
    class ElasticSearch < Base
      
      def default_alarms    

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressure'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 72
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressure'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 92
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ClusterIndexWritesBlocked'
        alarm.metric_name = 'ClusterIndexWritesBlocked'
        alarm.threshold = 1
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        @alarms.push(alarm)  
    end
  end
end