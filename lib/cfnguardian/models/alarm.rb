require 'cfnguardian/string'
require 'digest/md5'

module CfnGuardian
  module Models
    class BaseAlarm
      
      attr_reader :type,
        :resource_hash
        
      attr_accessor :group,
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
        :ok_action_disabled,
        :enabled,
        :resource_id,
        :resource_name,
        :alarm_action,
        :treat_missing_data,
        :datapoints_to_alarm,
        :extended_statistic,
        :evaluate_low_sample_count_percentile,
        :unit,
        :maintenance_groups,
        :additional_notifiers,
        :tags
      
      def initialize(resource)
        @type = 'Alarm'
        @group = nil
        @name = ''
        @metric_name = nil
        @namespace = nil
        @dimensions = nil
        @threshold = 0
        @period = 60
        @evaluation_periods = 1
        @comparison_operator = 'GreaterThanThreshold'
        @statistic = 'Maximum'
        @actions_enabled = true
        @ok_action_disabled = false
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
        @additional_notifiers = []
        @tags = {}
      end
      
      def metric_name=(metric_name)
        raise ArgumentError.new("metric_name '#{metric_name}' must be of type String, provided type '#{metric_name.class}'") unless metric_name.is_a?(String)
        @metric_name=metric_name
      end      
    end
    
    class AcmAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Acm'
        @namespace = 'AWS/CertificateManager'
        @dimensions = { CertificateArn: { "Fn::Sub" => "arn:aws:acm:${AWS::Region}:${AWS::AccountId}:certificate/#{resource['Id']}"}}
      end
    end

    class ApiGatewayAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ApiGateway'
        @namespace = 'AWS/ApiGateway'
        @dimensions = { ApiName: resource['Id'] }
        @treat_missing_data = 'notBreaching'
      end
    end
    
    class ApplicationTargetGroupAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ApplicationTargetGroup'
        @namespace = 'AWS/ApplicationELB'
        @dimensions = { 
          TargetGroup: resource['Id'],
          LoadBalancer: resource['LoadBalancer']
        }
      end
    end
    
    class AmazonMQBrokerAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'AmazonMQBroker'
        @namespace = 'AWS/AmazonMQ'
        @dimensions = { Broker: resource['Id'] }
      end
    end

    class AmazonMQRabbitMQBrokerAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'AmazonMQRabbitMQBroker'
        @namespace = 'AWS/AmazonMQ'
        @dimensions = { Broker: resource['Id'] }
      end
    end

    class AmazonMQRabbitMQNodeAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'AmazonMQRabbitMQNode'
        @namespace = 'AWS/AmazonMQ'
        @dimensions = { 
          Broker: resource['Id'],
          Node: resource['Node']
        }
      end
    end

    class AmazonMQRabbitMQQueueAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'AmazonMQRabbitMQQueue'
        @namespace = 'AWS/AmazonMQ'
        @dimensions = { 
          Broker: resource['Broker'],
          Queue: resource['Id'],
          VirtualHost: resource['Vhost']
        }
      end
    end
    
    class CloudFrontDistributionAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'CloudFrontDistribution'
        @namespace = 'AWS/CloudFront'
        @dimensions = { 
          DistributionId: resource['Id'],
          Region: 'Global'
        }
        @statistic = 'Average'
        @evaluation_periods = 5
        @treat_missing_data = 'notBreaching'
      end
    end
    
    class AutoScalingGroupAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'AutoScalingGroup'
        @namespace = 'AWS/EC2'
        @dimensions = { AutoScalingGroupName: resource['Id'] }
      end
    end

    class DMSTaskAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'DMSTask'
        @namespace = 'AWS/DMS'
        @dimensions = { 
          ReplicationTaskIdentifier: resource['Id'],
          ReplicationInstanceIdentifier: resource['Instance']
         }
      end
    end

    class DMSClusterAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'DMSCluster'
        @namespace = 'AWS/DMS'
        @dimensions = { 
          ReplicationInstanceIdentifier: resource['Id']
         }
      end
    end

    class DocumentDBClusterAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'DocumentDBCluster'
        @namespace = 'AWS/DocDB'
        @dimensions = { DBClusterIdentifier: resource['Id'] }
      end
    end
    
    class DomainExpiryAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'DomainExpiry'
        @namespace = 'DNS'
        @dimensions = { Domain: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
      end
    end
    
    class DynamoDBTableAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'DynamoDBTable'
        @namespace = 'AWS/DynamoDB'
        @dimensions = { TableName: resource['Id'] }
      end
    end
    
    class Ec2InstanceAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Ec2Instance'
        @namespace = 'AWS/EC2'
        @dimensions = { InstanceId: resource['Id'] }
      end
    end
    
    class ECSClusterAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ECSCluster'
        @namespace = 'AWS/ECS'
        @dimensions = { ClusterName: resource['Id'] }
        @threshold = 75
        @alarm_action = 'Warning'
        @evaluation_periods = 10
        @treat_missing_data = 'notBreaching'
      end
    end
    
    class ECSServiceAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ECSService'
        @namespace = 'AWS/ECS'
        @dimensions = {
          ServiceName: resource['Id'],
          ClusterName: resource['Cluster'] 
        }
        @treat_missing_data = 'breaching'
      end
    end

    class EKSContainerInsightsClusterAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'EKSContainerInsightsCluster'
        @namespace = 'ContainerInsights'
        @dimensions = { ClusterName: resource['Id'] }
      end
    end
    
    class EKSContainerInsightsNamespaceAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'EKSContainerInsightsNamespace'
        @namespace = 'ContainerInsights'
        @dimensions = { 
          ClusterName: resource['Cluster'],
          Namespace: resource['Id']
        }
      end
    end

    class ElastiCacheReplicationGroupAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ElastiCacheReplicationGroup'
        @namespace = 'AWS/ElastiCache'
        @dimensions = { CacheClusterId: resource['Id'] }
      end
    end

    class ElasticSearchAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ElasticSearch'
        @namespace = 'AWS/ES'
        @dimensions = { 
          DomainName: resource['Domain'], 
          ClientId: resource['Id'] 
        }
        @comparison_operator = 'GreaterThanOrEqualToThreshold'
        @threshold = 1
        @evaluation_periods = 5
        @treat_missing_data = 'breaching'
        @period = 60
        @data_points_to_alarm = 1
      end
    end
    
    class ElasticLoadBalancerAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'ElasticLoadBalancer'
        @namespace = 'AWS/ELB'
        @dimensions = { LoadBalancerName: resource['Id'] }
      end
    end
    
    class ElasticFileSystemAlarm < BaseAlarm
      def initialize(resource, storage_class = nil)
        super(resource)
        @group = 'ElasticFileSystem'
        @namespace = 'AWS/EFS'
        @dimensions = { FileSystemId: resource['Id'] }
        unless storage_class.nil?
          @dimensions[:StorageClass] = storage_class
        end
      end
    end
    
    class HttpAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Http'
        @namespace = 'HttpCheck'
        @dimensions = { Endpoint: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @evaluation_periods = 2
      end
    end

    class WebSocketAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'WebSocket'
        @namespace = 'WebSocketCheck'
        @dimensions = { Endpoint: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @evaluation_periods = 2
      end
    end

    class InternalHttpAlarm < HttpAlarm
      def initialize(resource)
        super(resource)
      end
    end

    class PortAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Port'
        @namespace = 'TcpPortCheck'
        @dimensions = { Endpoint: "#{resource['Id']}:#{resource['Port']}" }
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @evaluation_periods = 2
      end
    end

    class InternalPortAlarm < PortAlarm
      def initialize(resource)
        super(resource)
      end
    end
    
    class SslAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Ssl'
        @namespace = 'SSL'
        @dimensions = { URL: resource['Id'] }
        @comparison_operator = 'LessThanThreshold'
      end
    end

    class InternalSslAlarm < SslAlarm
      def initialize(resource)
        super(resource)
      end
    end
    
    class NrpeAlarm < BaseAlarm
      def initialize(resource,environment)
        super(resource)
        @group = 'Nrpe'
        @namespace = 'NRPE'
        @dimensions = { Host: "#{environment}-#{resource['Id']}" }
        @treat_missing_data = 'breaching'
        @evaluation_periods = 2
      end
    end

    class KafkaClusterAlarm < BaseAlarm
      def initialize(resource,broker)
        super(resource)
        @group = 'KafkaCluster'
        @namespace = 'AWS/Kafka'
        @dimensions = { 'Cluster Name': resource['Id'], 'Broker ID': broker }
        @statistic = 'Average'
        @evaluation_periods = 1
        @datapoints_to_alarm = 1
        @period = 300
        @treat_missing_data = 'breaching'
      end
    end

    class KafkaTopicAlarm < BaseAlarm
      def initialize(resource,broker)
        super(resource)
        @group = 'KafkaTopic'
        @namespace = 'AWS/Kafka'
        @dimensions = { 'Cluster Name': resource['ClusterName'], 'Broker ID': broker, Topic: resource['Id'] }
        @statistic = 'Average'
        @evaluation_periods = 1
        @datapoints_to_alarm = 1
        @period = 300
        @treat_missing_data = 'breaching'
      end
    end

    class LambdaAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Lambda'
        @namespace = 'AWS/Lambda'
        if resource['Id'].include?(':')
          lambda_name, lambda_alias = resource['Id'].split(':', 2)
          @dimensions = { FunctionName: lambda_name, Resource: resource['Id'] }
        else
          @dimensions = { FunctionName: resource['Id'] }
        end     
        @statistic = 'Average'
        @evaluation_periods = 5
        @treat_missing_data = 'notBreaching'
      end
    end
    
    class NetworkTargetGroupAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'NetworkTargetGroup'
        @namespace = 'AWS/NetworkELB'
        @dimensions = { 
          TargetGroup: resource['Id'],
          LoadBalancer: resource['LoadBalancer']
        }
      end
    end
    
    class RedshiftClusterAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'RedshiftCluster'
        @namespace = 'AWS/Redshift'
        @dimensions = { ClusterIdentifier: resource['Id'] }
      end
    end
    
    class RDSClusterInstanceAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'RDSClusterInstance'
        @namespace = 'AWS/RDS'
        @dimensions = { DBInstanceIdentifier: resource['Id'] }
      end
    end
    
    class RDSInstanceAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'RDSInstance'
        @namespace = 'AWS/RDS'
        @dimensions = { DBInstanceIdentifier: resource['Id'] }
      end
    end

    class StepFunctionsAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'StepFunctions'
        @namespace = 'AWS/States'
        @dimensions = { StateMachineArn: { "Fn::Sub" => "arn:aws:states:${AWS::Region}:${AWS::AccountId}:stateMachine:#{resource['Id']}"} }
      end
    end

    class BatchAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Batch'
      end
    end

    class GlueAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Batch'
        @namespace = 'Glue'
      end
    end

    class SqlAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Sql'
        @namespace = 'SQL'
        @dimensions = { Host: resource['Id'] }
        @treat_missing_data = 'breaching'
        @evaluation_periods = 1
      end
    end
    
    class SQSQueueAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'SQSQueue'
        @namespace = 'AWS/SQS'
        @dimensions = { QueueName: resource['Id'] }
        @statistic = 'Average'
        @period = 300
        @treat_missing_data = 'notBreaching'
      end
    end
    
    class LogGroupAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'LogGroup'
        @namespace = "MetricFilters"
        @statistic = 'Sum'
        @threshold = 1
        @period = 300
        @alarm_action = 'Informational'
        @treat_missing_data = 'notBreaching'
      end
    end
    
    class SFTPAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'SFTP'
        @namespace = 'SftpCheck'
        @period = 300
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @dimensions = { Host: resource['Id'], User: resource['User'] }
      end
    end

    class InternalSFTPAlarm < SFTPAlarm
      def initialize(resource)
        super(resource)
      end
    end
    
    class TLSAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'TLS'
        @namespace = 'TLSVersionCheck'
        @period = 300
        @port = resource.fetch('Port', 443)
        @dimensions = { Endpoint: "#{resource['Id']}:#{@port}" }
        @comparison_operator = 'LessThanThreshold'
        @threshold = 1
        @evaluation_periods = 1
      end
    end

    class AzureFileAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'AzureFile'
        @namespace = 'FileAgeCheck'
        @period = 300
        @comparison_operator = 'GreaterThanThreshold'
        @threshold = 0
        @dimensions = { StorageAccount: resource['Id'], StorageContainer: resource['Container'] }
      end
    end

    class JenkinsAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'Jenkins'
        @namespace = 'Ciinabox/Jenkins'
        @dimensions = { 
          Jenkins: resource['Id'],
          Label: resource['Label'],
          Monitoring: 'JenkMon'
        }
      end
    end

    class VPNTunnelAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'VPNTunnel'
        @namespace = 'AWS/VPN'
        @dimensions = {
          TunnelIpAddress: resource['Id']
        }
      end
    end

    class VPNConnectionAlarm < BaseAlarm
      def initialize(resource)
        super(resource)
        @group = 'VPNConnection'
        @namespace = 'AWS/VPN'
        @dimensions = {
          VpnId: resource['Id']
        }
      end
    end

  end
end
