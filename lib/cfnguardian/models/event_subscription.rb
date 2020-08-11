module CfnGuardian
    module Models
        class EventSubscription
            
            attr_reader :type, :group
            attr_accessor :name,
                :enabled,
                :hash,
                :topic,
                :resource_id,
                :resource_arn,
                :source,
                :detail_type

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
            end

            def detail
                return {}
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

        class Ec2EventSubscription < EventSubscription
            def initialize(resource)
                super(resource)
                @source = 'aws.ec2'
            end
        end

        class Ec2InstanceEventSubscription < Ec2EventSubscription
            attr_accessor :state

            def initialize(resource)
                super(resource)
                @detail_type = 'EC2 Instance State-change Notification'
            end

            def detail
                return {
                    'instance-id' => [@resource_id],
                    'state' => [@state]
                }
            end
        end
    end
end