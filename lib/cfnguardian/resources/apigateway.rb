module CfnGuardian::Resource
  class ApiGateway < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::ApiGatewayAlarm.new(@resource)
      alarm.name = 'ApiEndpoint5xx'
      alarm.metric_name = '5XXError'
      alarm.statistic = 'Sum'
      alarm.threshold = 5
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ApiGatewayAlarm.new(@resource)
      alarm.name = 'ApiEndpoint4xx'
      alarm.metric_name = '4XXError'
      alarm.statistic = 'Sum'
      alarm.threshold = 5
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ApiGatewayAlarm.new(@resource)
      alarm.name = 'Latency'
      alarm.metric_name = 'Latency'
      alarm.statistic = 'Average'
      alarm.threshold = 1000
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
    end
    
  end
end

