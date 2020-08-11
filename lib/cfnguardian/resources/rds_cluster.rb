module CfnGuardian::Resource
    class RDSCluster < Base
           
      def default_event_subscriptions()
        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverFailed'
        event_subscription.rds_event_category = 'failover'
        event_subscription.message = 'A failover for the DB cluster has failed.'
        @event_subscriptions.push(event_subscription)
      end
  
    end
  end
  