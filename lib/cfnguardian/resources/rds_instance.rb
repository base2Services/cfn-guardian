require 'aws-sdk-rds'

module CfnGuardian::Resource
  class RDSInstance < Base
    
    def default_alarms 
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'FreeStorageSpaceCritical'
      alarm.metric_name = 'FreeStorageSpace'
      alarm.threshold = 50000000000
      alarm.evaluation_periods = 1
      alarm.comparison_operator = 'LessThanThreshold'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'FreeStorageSpaceTask'
      alarm.metric_name = 'FreeStorageSpace'
      alarm.threshold = 100000000000
      alarm.evaluation_periods = 1
      alarm.comparison_operator = 'LessThanThreshold'
      alarm.alarm_action = 'Task'
      @alarms.push(alarm)
         
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighSpike'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 95
      alarm.evaluation_periods = 10
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'CPUUtilizationHighBase'
      alarm.metric_name = 'CPUUtilization'
      alarm.threshold = 75
      alarm.evaluation_periods = 60
      alarm.alarm_action = 'Warning'
      @alarms.push(alarm)
      
      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'DatabaseConnections'
      alarm.metric_name = 'DatabaseConnections'
      alarm.statistic = 'Minimum'
      alarm.threshold = 45
      alarm.evaluation_periods = 10
      @alarms.push(alarm)

      alarm = CfnGuardian::Models::RDSInstanceAlarm.new(@resource)
      alarm.name = 'ReplicaLag'
      alarm.metric_name = 'ReplicaLag'
      alarm.threshold = 30 # seconds
      alarm.evaluation_periods = 5
      alarm.alarm_action = 'Warning'
      alarm.enabled = false
      @alarms.push(alarm)
    end
    
    def default_event_subscriptions()
      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MasterPasswordReset'
      event_subscription.event_id = 'RDS-EVENT-0016'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MasterPasswordResetFailure'
      event_subscription.event_id = 'RDS-EVENT-0067'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'Deletion'
      event_subscription.event_id = 'RDS-EVENT-0003'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'StorageFullShutDown'
      event_subscription.event_id = 'RDS-EVENT-0221'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'StorageCapacityLow'
      event_subscription.event_id = 'RDS-EVENT-0222'
      @event_subscriptions.push(event_subscription)
      
      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'InvalidState'
      event_subscription.event_id = 'RDS-EVENT-0219'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'StorageScalingReachedThreshold'
      event_subscription.event_id = 'RDS-EVENT-0224'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'StorageScalingFailed'
      event_subscription.event_id = 'RDS-EVENT-0223'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MultiAZStandByFailoverStarted'
      event_subscription.event_id = 'RDS-EVENT-0013'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MultiAZStandByFailoverCompleted'
      event_subscription.event_id = 'RDS-EVENT-0015'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MultiAZFailoverStarted'
      event_subscription.event_id = 'RDS-EVENT-0050'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MultiAZFailoverCompleted'
      event_subscription.event_id = 'RDS-EVENT-0049'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'NotAttemptingFailover'
      event_subscription.event_id = 'RDS-EVENT-0034'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'DBFailure'
      event_subscription.event_id = 'RDS-EVENT-0031'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'TableCountExceedsRecommended'
      event_subscription.event_id = 'RDS-EVENT-0055'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'DatabasesCountExceedsRecommended'
      event_subscription.event_id = 'RDS-EVENT-0056'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'ReplicationFailure'
      event_subscription.enabled = false
      event_subscription.event_id = 'RDS-EVENT-0045'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'ReplicationTerminated'
      event_subscription.enabled = false
      event_subscription.event_id = 'RDS-EVENT-0057'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'ReplicationStopped'
      event_subscription.enabled = false
      event_subscription.event_id = 'RDS-EVENT-0062'
      @event_subscriptions.push(event_subscription)
    end

    def resource_exists?
      client = Aws::RDS::Client.new
      resource = Aws::RDS::Resource.new(client: client)
      instance = resource.db_instance(@resource['Id'])

      begin
        instance.load
      rescue Aws::RDS::Errors::DBInstanceNotFound
        return false
      end
      
      return true
    end

  end
end
