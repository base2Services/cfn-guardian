module CfnGuardian::Resource
  class ApiGatewayPath < Base
    
    def default_alarms    
      alarm = CfnGuardian::Models::ApiGatewayPathAlarm.new(@resource)
      alarm.name = 'ApiPath5xx'
      alarm.metric_name = '5XXError'
      alarm.statistic = 'Sum'
      alarm.threshold = 5
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ApiGatewayPathAlarm.new(@resource)
      alarm.name = 'ApiPath4xx'
      alarm.metric_name = '4XXError'
      alarm.statistic = 'Sum'
      alarm.threshold = 5
      alarm.evaluation_periods = 2
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::ApiGatewayPathAlarm.new(@resource)
      alarm.name = 'Latency'
      alarm.metric_name = 'Latency'
      alarm.statistic = 'Average'
      alarm.threshold = 1000
      alarm.evaluation_periods = 2
      @alarms.push(alarm)
    end
    
  end
end

