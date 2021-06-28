module CfnGuardian::Resource
    class ElasticSearch < Base
      
      def default_alarms    

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressureWarning'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 72
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        # Exceeding 92% mem pressure for a certian period results in writes being blocked
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressureCrit'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 92
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        @alarms.push(alarm)

        # Value of 1 indicates writes are blocked
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ClusterIndexWritesBlocked'
        alarm.metric_name = 'ClusterIndexWritesBlocked'
        alarm.threshold = 1 
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Critical'
        @alarms.push(alarm)  

        # Max % of CPU resources used by master nodes, recommended to increase node size if this reaches 60% 
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'MasterNodeCPUUtilisationWarning'
        alarm.metric_name = 'MasterCPUUtilization'
        alarm.threshold = 60
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)  

        #  Needs to be separated into active/unassigned/relocating/etc shards

        # alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        # alarm.name = 'ShardStatus'
        # alarm.metric_name = 'ShardStatus'
        # alarm.threshold = 1
        # alarm.evaluation_periods = 5
        # alarm.treat_missing_data = 'notBreaching'
        # @alarms.push(alarm)  

        # Search or Index latency? 
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'RequestLatency'
        alarm.metric_name = 'RequestLatency'
        alarm.threshold = 1
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        @alarms.push(alarm)  
        
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'RequestCount'
        alarm.metric_name = 'ElasticsearchRequests'
        alarm.threshold = 100 # placeholder
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.statistic = 'Sum'
        @alarms.push(alarm)  

        # alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        # alarm.name = 'RefreshTime'
        # alarm.metric_name = 'RefreshTime'
        # alarm.threshold = 1
        # alarm.evaluation_periods = 5
        # alarm.treat_missing_data = 'notBreaching'
        # @alarms.push(alarm)  

        # alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        # alarm.name = 'MergeQueue'
        # alarm.metric_name = 'ThreadpoolForce_mergeQueue'
        # alarm.threshold = 1
        # alarm.evaluation_periods = 5
        # alarm.treat_missing_data = 'notBreaching'
        # alarm.alarm_action = 'Warning'
        # alarm.statistic = 'Maximum'
        # @alarms.push(alarm)  
        
        # EBS IOPS
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ReadIOPS'
        alarm.metric_name = 'ReadIOPS'
        alarm.threshold = 100 # placeholder 
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm) 
        
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'WriteIOPS'
        alarm.metric_name = 'WriteIOPS'
        alarm.threshold = 100 # placeholder
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)  
        
        # FreeStorageSpace warning/crit (must be set at intervals of 1 min to be accurate)
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'FreeStorageSpaceWarning'
        alarm.metric_name = 'FreeStorageSpace'
        alarm.threshold = 1000000000 # placeholder
        alarm.evaluation_periods = 5
        alarm.period = 60 
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        alarm.statistic = 'Sum'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'FreeStorageSpaceCrit'
        alarm.metric_name = 'FreeStorageSpace'
        alarm.threshold = 100000000000 # placeholder
        alarm.evaluation_periods = 5
        alarm.period = 60 
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Critical'
        @alarms.push(alarm)  
        
        # CPU Utilisation warning/crit
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'CPUUtilizationWarning'
        alarm.metric_name = 'CPUUtilization'
        alarm.threshold = 75
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Warning'
        alarm.statistic = 'Average'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'CPUUtilizationCrit'
        alarm.metric_name = 'CPUUtilization'
        alarm.threshold = 95
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'notBreaching'
        alarm.alarm_action = 'Critical'
        alarm.statistic = 'Average'
        @alarms.push(alarm)  
    end
  end
end