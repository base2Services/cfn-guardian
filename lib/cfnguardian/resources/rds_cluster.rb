module CfnGuardian::Resource
    class RDSCluster < Base
           
      def default_event_subscriptions()
        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverFailed'
        event_subscription.rds_event_category = 'failover'
        event_subscription.message = 'A failover for the DB cluster has failed.'
        @event_subscriptions.push(event_subscription)

        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverFinished'
        event_subscription.rds_event_category = 'failover'
        event_subscription.message = 'A failover for the DB cluster has finished.'
        event_subscription.enabled = false
        @event_subscriptions.push(event_subscription)
      end
  
      def resource_exists?
        client = Aws::RDS::Client.new
        resource = Aws::RDS::Resource.new(client: client)
        instance = resource.db_cluster(@resource['Id'])
  
        begin
          instance.load
        rescue Aws::RDS::Errors::DBClusterNotFoundFault
          return false
        end
        
        return true
      end

    end
  end
  