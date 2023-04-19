module CfnGuardian::Resource
  class CloudFrontDistribution < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::CloudFrontDistributionAlarm.new(@resource)
      alarm.name = '4xxErrorRate'
      alarm.metric_name = '4xxErrorRate'
      alarm.threshold = 10
      alarm.statistic = 'Average'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::CloudFrontDistributionAlarm.new(@resource)
      alarm.name = '5xxErrorRate'
      alarm.metric_name = '5xxErrorRate'
      alarm.statistic = 'Average'
      alarm.threshold = 10
      @alarms.push(alarm)
    end
    
  end
end
