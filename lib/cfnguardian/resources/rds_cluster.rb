module CfnGuardian::Resource
    class RDSCluster < Base
           
      def default_event_subscriptions()
        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverFailed'
        event_subscription.event_id = 'RDS-EVENT-0069'
        @event_subscriptions.push(event_subscription)

        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverFinished'
        event_subscription.event_id = 'RDS-EVENT-0071'
        @event_subscriptions.push(event_subscription)

        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverStartedSameAZ'
        event_subscription.event_id = 'RDS-EVENT-0072'
        @event_subscriptions.push(event_subscription)

        event_subscription = CfnGuardian::Models::RDSClusterEventSubscription.new(@resource)
        event_subscription.name = 'FailoverStartedDifferentAZ'
        event_subscription.event_id = 'RDS-EVENT-0073'
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
  