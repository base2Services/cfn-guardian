module CfnGuardian::Resource
    class ElasticSearch < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressure'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 92 # if JVMMemoryPressure reaches 92% cluster index writes are blocked
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ClusterIndexWritesBlocked'
        alarm.metric_name = 'ClusterIndexWritesBlocked'
        alarm.threshold = 1 # 0 means elasticsearch is accepting requests, 1 means they're blocked
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        @alarms.push(alarm)  
    end
  end