module CfnGuardian::Resource
  class EKSContainerInsightsCluster < Base

    def default_alarms

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'NodeCpuUtilisationBase'
      alarm.metric_name = 'node_cpu_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 75
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'NodeCpuUtilisationSpike'
      alarm.metric_name = 'node_cpu_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 95
      alarm.evaluation_periods = 5
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'NodeFileSystemUtilisationCrit'
      alarm.metric_name = 'node_cpu_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 90
      alarm.evaluation_periods = 1
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'NodeFileSystemUtilisationWarning'
      alarm.metric_name = 'node_cpu_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 75
      alarm.evaluation_periods = 1
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'NodeMemoryUtilisationBase'
      alarm.metric_name = 'node_memory_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 80
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'NodeMemoryUtilisationSpike'
      alarm.metric_name = 'node_memory_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 90
      alarm.evaluation_periods = 5
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsClusterAlarm.new(@resource)
      alarm.name = 'ClusterFailedNodeCount'
      alarm.metric_name = 'cluster_failed_node_count'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Minimum'
      alarm.threshold = 0
      alarm.evaluation_periods = 1
      @alarms.push(alarm)

    end
  end

  class EKSContainerInsightsNamespace < Base

    def default_alarms

      alarm = CfnGuardian::Models::EKSContainerInsightsNamespaceAlarm.new(@resource)
      alarm.name = 'PodCpuUtilisation'
      alarm.metric_name = 'pod_cpu_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 90
      alarm.evaluation_periods = 5
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::EKSContainerInsightsNamespaceAlarm.new(@resource)
      alarm.name = 'PodMemoryUtilisation'
      alarm.metric_name = 'pod_memory_utilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 90
      alarm.evaluation_periods = 5
      @alarms.push(alarm)

    end
  end
end 