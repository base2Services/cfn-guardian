module CfnGuardian::Resource
  class CloudFrontDistribution < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::CloudFrontDistributionAlarm.new(@resource)
      alarm.name = '4xxErrorRate'
      alarm.metric_name = '4xxErrorRate'
      alarm.threshold = 2
      alarm.statistic = 'Sum'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::CloudFrontDistributionAlarm.new(@resource)
      alarm.name = '5xxErrorRate'
      alarm.metric_name = '5xxErrorRate'
      alarm.threshold = 5
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::CloudFrontDistributionAlarm.new(@resource)
      alarm.name = 'TotalErrorRate'
      alarm.metric_name = 'TotalErrorRate'
      alarm.threshold = 5
      @alarms.push(alarm)
    end
    
  end
end
