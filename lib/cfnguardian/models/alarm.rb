require 'cfnguardian/string'
require 'digest/md5'

module CfnGuardian
  module Models
    class Alarm
      
      attr_reader :type,
        :resource_hash
        
      attr_accessor :class,
        :name,
        :metric_name,
        :namespace,
        :dimensions,
        :threshold,
        :period,
        :evaluation_periods,
        :comparison_operator,
        :statistic,
        :actions_enabled,
        :enabled,
        :resource_id,
        :resource_name,
        :alarm_action,
        :treat_missing_data,
        :datapoints_to_alarm,
        :extended_statistic,
        :evaluate_low_sample_count_percentile,
        :unit,
        :maintenance_groups
      
      def initialize(resource)
        @type = 'Alarm'
        @class = nil
        @name = ''
        @metric_name = nil
        @namespace = nil
        @dimensions = {}
        @threshold = 0
        @period = 60
        @evaluation_periods = 1
        @comparison_operator = 'GreaterThanThreshold'
        @statistic = 'Maximum'
        @actions_enabled = true
        @datapoints_to_alarm = nil
        @extended_statistic = nil
        @evaluate_low_sample_count_percentile = nil
        @unit = nil
        @enabled = true
        @resource_hash = Digest::MD5.hexdigest resource['Id']
        @resource_id = resource['Id']
        @resource_name = resource.fetch('Name', nil)
        @alarm_action = 'Critical'
        @treat_missing_data = nil
        @maintenance_groups = []
      end
      
      def metric_name=(metric_name)
        raise ArgumentError.new("metric_name '#{metric_name}' must be of type String, provided type '#{metric_name.class}'") unless metric_name.is_a?(String)
        @metric_name=metric_name
      end      
    end
    
    
    class ApiGatewayAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ApiGateway'
        @namespace = 'AWS/ApiGateway'
        @dimensions = { ApiName: resource['Id'] }
      end
    end
    
    class ApplicationTargetGroupAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ApplicationTargetGroup'
        @namespace = 'AWS/ApplicationELB'
        @dimensions = { 
          TargetGroup: resource['Id'],
          LoadBalancer: resource['LoadBalancer']
        }
      end
    end
    
    class AmazonMQBrokerAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'AmazonMQBroker'
        @namespace = 'AWS/AmazonMQ'
        @dimensions = { Broker: resource['Id'] }
      end
    end
    
    class CloudFrontDistributionAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'CloudFrontDistribution'
        @namespace = 'AWS/CloudFront'
        @dimensions = { 
          DistributionId: resource['Id'],
          Region: 'Global'
        }
        @statistic = 'Average'
        @evaluation_periods = 5
      end
    end
    
    class AutoScalingGroupAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'AutoScalingGroup'
        @namespace = 'AWS/EC2'
        @dimensions = { AutoScalingGroupName: resource['Id'] }
      end
    end
    
    class DomainExpiryAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'DomainExpiry'
        @namespace = 'DNS'
        @dimensions = { Domain: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
      end
    end
    
    class DynamoDBTableAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'DynamoDBTable'
        @namespace = 'AWS/DynamoDB'
        @dimensions = { TableName: resource['Id'] }
      end
    end
    
    class Ec2InstanceAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'Ec2Instance'
        @namespace = 'AWS/EC2'
        @dimensions = { InstanceId: resource['Id'] }
      end
    end
    
    class ECSClusterAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ECSCluster'
        @namespace = 'AWS/ECS'
        @dimensions = { ClusterName: resource['Id'] }
        @threshold = 75
        @alarm_action = 'Warning'
        @evaluation_periods = 10
      end
    end
    
    class ECSServiceAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ECSService'
        @namespace = 'AWS/ECS'
        @dimensions = {
          ServiceName: resource['Id'],
          ClusterName: resource['Cluster'] 
        }
      end
    end
    
    class ElastiCacheReplicationGroupAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ElastiCacheReplicationGroup'
        @namespace = 'AWS/ElastiCache'
        @dimensions = { CacheClusterId: resource['Id'] }
      end
    end
    
    class ElasticLoadBalancerAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ElasticLoadBalancer'
        @namespace = 'AWS/ELB'
        @dimensions = { LoadBalancerName: resource['Id'] }
      end
    end
    
    class ElasticFileSystemAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'ElasticFileSystem'
        @namespace = 'AWS/EFS'
        @dimensions = { FileSystemId: resource['Id'] }
      end
    end
    
    class HttpAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'Http'
        @namespace = 'HttpCheck'
        @dimensions = { Endpoint: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @evaluation_periods = 2
      end
    end

    class PortAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'Port'
        @namespace = 'TcpPortCheck'
        @dimensions = { Endpoint: "#{resource['Id']}:#{resource['Port']}" }
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @evaluation_periods = 2
      end
    end
    
    class SslAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'Ssl'
        @namespace = 'SSL'
        @dimensions = { URL: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
      end
    end
    
    class NrpeAlarm < Alarm
      def initialize(resource,environment)
        super(resource)
        @class = 'Nrpe'
        @namespace = 'NRPE'
        @dimensions = { Host: "#{environment}-#{resource['Id']}" }
        @treat_missing_data = 'breaching'
        @evaluation_periods = 2
      end
    end

    class LambdaAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'Lambda'
        @namespace = 'AWS/Lambda'
        @dimensions = { FunctionName: resource['Id'] }
        @statistic = 'Average'
        @evaluation_periods = 5
      end
    end
    
    class NetworkTargetGroupAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'NetworkTargetGroup'
        @namespace = 'AWS/NetworkELB'
        @dimensions = { 
          TargetGroup: resource['Id'],
          LoadBalancer: resource['LoadBalancer']
        }
      end
    end
    
    class RedshiftClusterAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'RedshiftCluster'
        @namespace = 'AWS/Redshift'
        @dimensions = { ClusterIdentifier: resource['Id'] }
      end
    end
    
    class RDSClusterInstanceAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'RDSClusterInstance'
        @namespace = 'AWS/RDS'
        @dimensions = { DBInstanceIdentifier: resource['Id'] }
      end
    end
    
    class RDSInstanceAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'RDSInstance'
        @namespace = 'AWS/RDS'
        @dimensions = { DBInstanceIdentifier: resource['Id'] }
      end
    end
    
    class SqlAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'Sql'
        @namespace = 'SQL'
        @dimensions = { Host: resource['Id'] }
        @treat_missing_data = 'breaching'
        @evaluation_periods = 1
      end
    end
    
    class SQSQueueAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'SQSQueue'
        @namespace = 'AWS/SQS'
        @dimensions = { QueueName: resource['Id'] }
        @statistic = 'Average'
        @period = 300
      end
    end
    
    class LogGroupAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'LogGroup'
        @namespace = "MetricFilters"
        @statistic = 'Sum'
        @threshold = 1
        @period = 300
        @alarm_action = 'Informational'
      end
    end
    
  end
end
