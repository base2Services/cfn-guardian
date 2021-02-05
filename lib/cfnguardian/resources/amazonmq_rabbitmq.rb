module CfnGuardian::Resource
  class AmazonMQRabbitMQBroker < Base
      
    def default_alarms
      alarm = CfnGuardian::Models::AmazonMQRabbitMQBrokerAlarm.new(@resource)
      alarm.name = 'ConnectionCountCritical'
      alarm.metric_name = 'ConnectionCount'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 50
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQBrokerAlarm.new(@resource)
      alarm.name = 'ConnectionCountWarn'
      alarm.metric_name = 'ConnectionCount'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 25
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQBrokerAlarm.new(@resource)
      alarm.name = 'MessageCountCritical'
      alarm.metric_name = 'MessageCount'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 500
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQBrokerAlarm.new(@resource)
      alarm.name = 'MessageCountWarn'
      alarm.metric_name = 'MessageCount'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 250
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

    end
  end

  class AmazonMQRabbitMQQueue < Base
      
    def default_alarms

      alarm = CfnGuardian::Models::AmazonMQRabbitMQQueueAlarm.new(@resource)
      alarm.name = 'MessageCountHighWarn'
      alarm.metric_name = 'MessageCount'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 100
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

    end
  end

  class AmazonMQRabbitMQNode < Base

    def default_alarms
      alarm = CfnGuardian::Models::AmazonMQRabbitMQNodeAlarm.new(@resource)
      alarm.name = 'SystemCpuUtilizationCritical'
      alarm.metric_name = 'SystemCpuUtilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 95
      alarm.evaluation_periods = 10
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQNodeAlarm.new(@resource)
      alarm.name = 'SystemCpuUtilizationHighBase'
      alarm.metric_name = 'SystemCpuUtilization'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 75
      alarm.evaluation_periods = 30
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQNodeAlarm.new(@resource)
      alarm.name = 'RabbitMQMemUsedCritical'
      alarm.metric_name = 'RabbitMQMemUsed'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 390000000
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQNodeAlarm.new(@resource)
      alarm.name = 'RabbitMQMemUsedWarn'
      alarm.metric_name = 'RabbitMQMemUsed'
      alarm.comparison_operator = 'GreaterThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 350000000
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQNodeAlarm.new(@resource)
      alarm.name = 'RabbitMQDiskFreeLimitCritical'
      alarm.metric_name = 'RabbitMQDiskFreeLimit'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 1200000000
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::AmazonMQRabbitMQNodeAlarm.new(@resource)
      alarm.name = 'RabbitMQDiskFreeLimitWarn'
      alarm.metric_name = 'RabbitMQDiskFreeLimit'
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.statistic = 'Maximum'
      alarm.threshold = 1200000000
      alarm.evaluation_periods = 5
      alarm.treat_missing_data = 'notBreaching'
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)

    end
  end
end