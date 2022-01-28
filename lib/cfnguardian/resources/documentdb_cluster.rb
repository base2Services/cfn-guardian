module CfnGuardian::Resource
    class DocumentDBCluster < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::DocumentDBClusterAlarm.new(@resource)
        alarm.name = 'CPUUtilizationHighBase'
        alarm.metric_name = 'CPUUtilization'
        alarm.threshold = 75
        alarm.evaluation_periods = 60
        alarm.alarm_action = 'Warning'
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::DocumentDBClusterAlarm.new(@resource)
        alarm.name = 'CPUUtilizationHighSpike'
        alarm.metric_name = 'CPUUtilization'
        alarm.threshold = 95
        alarm.evaluation_periods = 10
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::DocumentDBClusterAlarm.new(@resource)
        alarm.name = 'DatabaseConnections'
        alarm.metric_name = 'DatabaseConnections'
        alarm.statistic = 'Minimum'
        alarm.threshold = 50
        alarm.evaluation_periods = 10
        @alarms.push(alarm)

        alarm = CfnGuardian::Models::DocumentDBClusterAlarm.new(@resource)
        alarm.name = 'FreeableMemory'
        alarm.metric_name = 'FreeableMemory'
        alarm.threshold = 1000000000
        alarm.evaluation_periods = 3
        alarm.comparison_operator = 'LessThanThreshold'
        @alarms.push(alarm)
      end
      
    end
  end
  
  