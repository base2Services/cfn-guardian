module CfnGuardian
  module Resource
    class Ec2Instance < Base
      
      def default_alarms    
        alarm = CfnGuardian::Models::Ec2InstanceAlarm.new(@resource)
        alarm.name = 'CPUUtilizationHigh'
        alarm.metric_name = 'CPUUtilization'
        alarm.statistic = 'Minimum'
        alarm.threshold = 90
        alarm.evaluation_periods = 10
        @alarms.push(alarm)
        
        alarm = CfnGuardian::Models::Ec2InstanceAlarm.new(@resource)
        alarm.name = 'StatusCheckFailed'
        alarm.metric_name = 'StatusCheckFailed'
        alarm.threshold = 90
        alarm.evaluation_periods = 10
        @alarms.push(alarm)
      end
      
    end
  end
end
