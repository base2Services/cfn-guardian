module CfnGuardian
    module Models
        class EventSubscription
            
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

        class RDSEventSubscription < EventSubscription
            attr_accessor :source_id, :rds_event_category, :message

            def initialize(resource)
                super(resource)
                @source = 'aws.rds'
                @detail_type = 'RDS DB Instance Event'
                @source_id = ''
                @rds_event_category = ''
                @message = ''
            end

            def detail
                return {
                    EventCategories: [@rds_event_category],
                    SourceType: [@source_type],
                    SourceIdentifier: ["rds:#{@resource_id}"],
                    Message: [@message]
                }
            end
        end

        class RDSInstanceEventSubscription < RDSEventSubscription
            def initialize(resource)
                super(resource)
                @source_type = 'DB_INSTANCE'
            end
        end

        class RDSClusterEventSubscription < RDSEventSubscription
            def initialize(resource)
                super(resource)
                @source_type = 'DB_CLUSTER'
            end
        end

        class Ec2InstanceEventSubscription < EventSubscription
            def initialize(resource)
                super(resource)
                @source = 'aws.ec2'
            end
        end

        class ApiGatewayEventSubscription < EventSubscription; end
        class ApplicationTargetGroupEventSubscription < EventSubscription; end
        class AmazonMQBrokerEventSubscription < EventSubscription; end
        class CloudFrontDistributionEventSubscription < EventSubscription; end
        class AutoScalingGroupEventSubscription < EventSubscription; end
        class DynamoDBTableEventSubscription < EventSubscription; end
        class Ec2InstanceEventSubscription < EventSubscription; end
        class ECSClusterEventSubscription < EventSubscription; end
        class ECSServiceEventSubscription < EventSubscription; end
        class ElastiCacheReplicationGroupEventSubscription < EventSubscription; end
        class ElasticLoadBalancerEventSubscription < EventSubscription; end
        class ElasticFileSystemEventSubscription < EventSubscription; end
        class LambdaEventSubscription < EventSubscription; end
        class NetworkTargetGroupEventSubscription < EventSubscription; end
        class RedshiftClusterEventSubscription < EventSubscription; end
    end
end