require 'cfnguardian/string'

module CfnGuardian
  module Models
    class Alarm
      
      attr_reader :type
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
        :resource,
        :required,
        :alarm_action,
        :treat_missing_data
      
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
        @enabled = true
        @resource_name = Digest::MD5.hexdigest resource['Id']
        @resource = resource['Id']
        @required = %w(type class name metric_name namespace dimensions threshold period evaluation_periods 
          comparison_operator statistic actions_enabled resource)
        @alarm_action = 'Critical'
        @treat_missing_data = nil
      end
      
      def metric_name=(metric_name)
        raise ArgumentError.new("metric_name '#{metric_name}' must be of type String, provided type '#{metric_name.class}'") unless metric_name.is_a?(String)
        @metric_name=metric_name
      end
      
      def to_h
        Hash[instance_variables.map { |name| [name[1..-1].to_sym, instance_variable_get(name)] } ]
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
    
    class AutoscalingGroupAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'AutoscalingGroup'
        @namespace = 'AWS/EC2'
        @dimensions = { AutoScalingGroupName: resource['Id'] }
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
    
    class EcsClusterAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'EcsCluster'
        @namespace = 'AWS/ECS'
        @dimensions = { ClusterName: resource['Id'] }
        @threshold = 75
        @alarm_action = 'Warning'
        @evaluation_periods = 10
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
    
    class RDSClusterInstanceAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'RDSClusterInstance'
        @namespace = 'AWS/RDS'
        @dimensions = { DBInstanceIdentifier: resource['Id'] }
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
    
    class RDSClusterAlarm < Alarm
      def initialize(resource)
        super(resource)
        @class = 'RDSCluster'
        @namespace = 'AWS/RDS'
        @dimensions = { DBClusterIdentifier: resource['Id'] }
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
    
  end
end
