module CfnGuardian::Resource
    class VPNTunnel < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::VPNTunnelAlarm.new(@resource)
        alarm.name = 'VPNTunnelState'
        alarm.metric_name = 'TunnelState'
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.statistic = 'Minimum'
        alarm.threshold = 1
        alarm.evaluation_periods = 5
        alarm.treat_missing_data = 'breaching'
        alarm.datapoints_to_alarm = 5
        @alarms.push(alarm)
      end
      
    end
end
