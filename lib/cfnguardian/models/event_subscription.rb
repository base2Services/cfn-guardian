module CfnGuardian
  module Models
    class BaseEventSubscription
        
      attr_reader :type, :group
      attr_writer :detail
      attr_accessor :name,
        :enabled,
        :hash,
        :topic,
        :resource_id,
        :resource_arn,
        :source,
        :detail_type,
        :detail

      def initialize(resource)
        @type = 'EventSubscription'
        @group = self.class.name.split('::').last
        @name = ''
        @hash = Digest::MD5.hexdigest resource['Id']
        @enabled = true
        @events = []
        @topic = 'Events'
        @resource_id = resource['Id']
        @resource_arn = ''
        @source = ''
        @detail_type = ''
        @detail = {}
      end

      def detail
        return @detail
      end
    end

    class RDSEventSubscription < BaseEventSubscription
      attr_accessor :event_id

      def initialize(resource)
        super(resource)
        @source = 'aws.rds'
        @event_id = nil
      end

      def detail
        if @event_id.nil?
          raise "#{self.class} missing `EventID` property"
        end

        return { EventID: [@event_id] }
      end
    end

    class RDSInstanceEventSubscription < RDSEventSubscription
      def initialize(resource)
        super(resource)
        @resource_arn = "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:db:#{@resource_id}"
      end
    end

    class RDSClusterEventSubscription < RDSEventSubscription
      def initialize(resource)
        super(resource)
        @resource_arn = "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:cluster:#{@resource_id}"
      end
    end


    class RDSClusterInstanceEventSubscription < RDSEventSubscription
      def initialize(resource)
        super(resource)
        @resource_arn = "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:db:#{@resource_id}"
      end
    end

    class Ec2InstanceEventSubscription < BaseEventSubscription
      def initialize(resource)
        super(resource)
        @source = 'aws.ec2'
      end
    end

    class BatchEventSubscription < BaseEventSubscription
      def initialize(resource)
        super(resource)
        @source = 'aws.batch'
      end
    end

    class GlueEventSubscription < BaseEventSubscription
      def initialize(resource)
        super(resource)
        @source = 'aws.glue'
      end
    end

    class AcmEventSubscription < BaseEventSubscription; end
    class ApiGatewayEventSubscription < BaseEventSubscription; end
    class ApplicationTargetGroupEventSubscription < BaseEventSubscription; end
    class AmazonMQBrokerEventSubscription < BaseEventSubscription; end
    class CloudFrontDistributionEventSubscription < BaseEventSubscription; end
    class AutoScalingGroupEventSubscription < BaseEventSubscription; end
    class DynamoDBTableEventSubscription < BaseEventSubscription; end
    class Ec2InstanceEventSubscription < BaseEventSubscription; end
    class ECSClusterEventSubscription < BaseEventSubscription; end
    class ECSServiceEventSubscription < BaseEventSubscription; end
    class ElastiCacheReplicationGroupEventSubscription < BaseEventSubscription; end
    class ElasticLoadBalancerEventSubscription < BaseEventSubscription; end
    class ElasticFileSystemEventSubscription < BaseEventSubscription; end
    class LambdaEventSubscription < BaseEventSubscription; end
    class NetworkTargetGroupEventSubscription < BaseEventSubscription; end
    class RedshiftClusterEventSubscription < BaseEventSubscription; end
    class StepFunctionsSubscription < BaseEventSubscription; end
    class VPNTunnelEventSubscription < BaseEventSubscription; end
    class VPNConnectionEventSubscription < BaseEventSubscription; end
  end
end