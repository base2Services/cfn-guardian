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
      event_subscription.rds_event_category = 'configuration change'
      event_subscription.message = 'The master password for the DB instance has been reset.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MasterPasswordResetFailure'
      event_subscription.rds_event_category = 'configuration change'
      event_subscription.message = 'An attempt to reset the master password for the DB instance has failed.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'Deletion'
      event_subscription.rds_event_category = 'deletion'
      event_subscription.message = 'The DB instance has been deleted.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MultiAZFailoverStarted'
      event_subscription.rds_event_category = 'failover'
      event_subscription.message = 'A Multi-AZ failover that resulted in the promotion of a standby instance has started.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'MultiAZFailoverComplete'
      event_subscription.rds_event_category = 'failover'
      event_subscription.message = 'A Multi-AZ failover has completed.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'DBFailure'
      event_subscription.rds_event_category = 'failure'
      event_subscription.message = 'The DB instance has failed due to an incompatible configuration or an underlying storage issue. Begin a point-in-time-restore for the DB instance.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'TableCountExceedsRecommended'
      event_subscription.rds_event_category = 'notification'
      event_subscription.message = 'The number of tables you have for your DB instance exceeds the recommended best practices for Amazon RDS.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'DatabasesCountExceedsRecommended'
      event_subscription.rds_event_category = 'notification'
      event_subscription.message = 'The number of databases you have for your DB instance exceeds the recommended best practices for Amazon RDS.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'ReplicationFailure'
      event_subscription.enabled = false
      event_subscription.rds_event_category = 'read replica'
      event_subscription.message = 'An error has occurred in the read replication process.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'ReplicationTerminated'
      event_subscription.enabled = false
      event_subscription.rds_event_category = 'read replica'
      event_subscription.message = 'Replication on the read replica was terminated.'
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::RDSInstanceEventSubscription.new(@resource)
      event_subscription.name = 'ReplicationStopped'
      event_subscription.enabled = false
      event_subscription.rds_event_category = 'read replica'
      event_subscription.message = 'Replication on the read replica was manually stopped.'
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
