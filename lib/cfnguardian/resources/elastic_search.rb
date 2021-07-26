module CfnGuardian::Resource
    class ElasticSearch < Base

      def default_alarms    
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'NodeCount'
        alarm.metric_name = 'Nodes'
        alarm.threshold = 3
        alarm.evaluation_periods = 1440 # 24 hours
        alarm.datapoints_to_alarm = 1
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        alarm.alarm_action = 'Critical'
        alarm.enabled = false
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressureWarning'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 72
        alarm.evaluation_periods = 5
        alarm.datapoints_to_alarm = 3
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'JVMMemoryPressureCrit'
        alarm.metric_name = 'JVMMemoryPressure'
        alarm.threshold = 92
        alarm.evaluation_periods = 5
        alarm.alarm_action = 'Critical'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ClusterIndexWritesBlocked'
        alarm.metric_name = 'ClusterIndexWritesBlocked'
        alarm.threshold = 1
        alarm.evaluation_periods = 5
        alarm.alarm_action = 'Critical'
        @alarms.push(alarm)  
        
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'MasterNodeCPUUtilisationWarning'
        alarm.metric_name = 'MasterCPUUtilization'
        alarm.threshold = 75
        alarm.evaluation_periods = 60
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'MasterNodeCPUUtilisationCrit'
        alarm.metric_name = 'MasterCPUUtilization'
        alarm.threshold = 95
        alarm.evaluation_periods = 10
        alarm.alarm_action = 'Critical'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'FreeStorageSpaceWarning'
        alarm.metric_name = 'FreeStorageSpace'
        alarm.threshold = 50000
        alarm.evaluation_periods = 1
        alarm.alarm_action = 'Warning'
        alarm.statistic = 'Minimum'
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'FreeStorageSpaceCrit'
        alarm.metric_name = 'FreeStorageSpace'
        alarm.threshold = 25000
        alarm.evaluation_periods = 1
        alarm.alarm_action = 'Critical'
        alarm.comparison_operator = 'LessThanOrEqualToThreshold'
        @alarms.push(alarm)  
       
        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'CPUUtilizationWarning'
        alarm.metric_name = 'CPUUtilization'
        alarm.threshold = 75
        alarm.evaluation_periods = 15
        alarm.datapoints_to_alarm = 3
        alarm.alarm_action = 'Warning'
        alarm.statistic = 'Average'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'CPUUtilizationCrit'
        alarm.metric_name = 'CPUUtilization'
        alarm.threshold = 95
        alarm.evaluation_periods = 5
        alarm.datapoints_to_alarm = 3
        alarm.alarm_action = 'Critical'
        alarm.statistic = 'Average'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'KMSKeyError'
        alarm.metric_name = 'KMSKeyError'
        alarm.threshold = 1
        alarm.evaluation_periods = 1
        alarm.alarm_action = 'Warning'
        alarm.statistic = 'Minimum'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'KMSKeyInaccessible'
        alarm.metric_name = 'KMSKeyInaccessible'
        alarm.threshold = 1
        alarm.evaluation_periods = 1
        alarm.alarm_action = 'Critical'
        alarm.statistic = 'Minimum'
        alarm.enabled = false
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ClusterStatusRed'
        alarm.metric_name = 'ClusterStatus.red'
        alarm.threshold = 1
        alarm.evaluation_periods = 1
        alarm.alarm_action = 'Critical'
        alarm.statistic = 'Minimum'
        @alarms.push(alarm)  

        alarm = CfnGuardian::Models::ElasticSearchAlarm.new(@resource)
        alarm.name = 'ClusterStatusYellow'
        alarm.metric_name = 'ClusterStatus.yellow'
        alarm.threshold = 1
        alarm.evaluation_periods = 1
        alarm.alarm_action = 'Warning'
        alarm.statistic = 'Minimum'
        @alarms.push(alarm)  

    end
  end
end
