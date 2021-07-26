module CfnGuardian::Resource
    class VPNConnection < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::VPNConnectionAlarm.new(@resource)
        alarm.name = 'VPNConnectionStateNonRedundant'
        alarm.metric_name = 'TunnelState'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'Average'
        alarm.threshold = 1.0
        alarm.evaluation_periods = 3
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 3
        @alarms.push(alarm)
      end

      def default_alarms    
        alarm = CfnGuardian::Models::VPNConnectionAlarm.new(@resource)
        alarm.name = 'VPNConnectionStateAllDown'
        alarm.metric_name = 'TunnelState'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'Average'
        alarm.threshold = 0.5
        alarm.evaluation_periods = 3
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 3
        @alarms.push(alarm)
      end
      
    end
end
