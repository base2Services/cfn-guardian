require 'cfnguardian/string'

module CfnGuardian
  module Models
    class Check
      
      attr_reader :type
      attr_accessor :class,
        :name,
        :handler,
        :version,
        :runtime,
        :environment
        
      def initialize(resource)
        @type = 'Check'
        @class = nil
        @name = nil
        @package = nil
        @handler = nil
        @version = nil
        @runtime = nil
        @environment = ''
      end
      
      def to_h
        Hash[instance_variables.map { |name| [name[1..-1].to_sym, instance_variable_get(name)] } ]
      end
    end
    
    class HttpCheck < Check      
      def initialize(resource)
        super(resource)
        @class = 'Http'
        @name = 'HttpCheck'
        @package = 'http-check'
        @handler = 'handler.main'
        @version = '702701918413c40b461843832fc2d3b1e80c0866'
        @runtime = 'python3.6'
      end
    end
    
    class PortCheck < Check      
      def initialize(resource)
        super(resource)
        @class = 'Port'
        @name = 'PortCheck'
        @package = 'port-check'
        @handler = 'handler.main'
        @version = '356203b2a720ba0730622f978e677b88f8d0c328'
        @runtime = 'python3.6'
      end
    end
    
    class InternalHttpCheck < HttpCheck
      attr_accessor :subnets, :vpc
       
      def initialize(resource)
        super(resource)
        @class = 'InternalHttp'
        @name = 'InternalHttpCheck'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end
    
    class NrpeCheck < Check
      attr_accessor :subnets, :vpc
      
      def initialize(resource)
        super(resource)
        @class = 'Nrpe'
        @name = 'NrpeCheck'
        @package = 'aws-lambda-nrpe-check'
        @handler = 'main'
        @version = 'aa51a0ad497a6c012a3639da0eb3446e4c0f9540'
        @runtime = 'go1.x'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end
    
    class SslCheck < Check
      def initialize(resource)
        super(resource)
        @class = 'Ssl'
        @name = 'SslCheck'
        @package = 'aws-lambda-ssl-check'
        @handler = 'main'
        @version = 'a25fd4006d1f95c06f3c098188543f5eea1986da'
        @runtime = 'go1.x'
      end
    end
    
    class DomainExpiryCheck < Check
      def initialize(resource)
        super(resource)
        @class = 'DomainExpiry'
        @name = 'DomainExpiryCheck'
        @package = 'aws-lambda-dns-check'
        @handler = 'main'
        @version = '9db96ca32379faddc47e55849b7e296b7b70a48e'
        @runtime = 'go1.x'
      end
    end
    
    class SqlCheck < Check
      attr_accessor :subnets, :vpc
      
      def initialize(resource)
        super(resource)
        @class = 'Sql'
        @name = 'SqlCheck'
        @package = 'aws-lambda-sql-check'
        @handler = 'main'
        @version = '83bd6399c0376c98df90dd5f29e49d629c556cee'
        @runtime = 'go1.x'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end
    
    class ContainerInstanceCheck < Check
      def initialize(resource)
        super(resource)
        @class = 'ContainerInstance'
        @name = 'ContainerInstanceCheck'
        @package = 'ecs-containder-instance-check'
        @handler = 'handler.run_check'
        @version = '4f650d5846d6e8d19f0139bccdeeb147f03f0dd6'
        @runtime = 'python3.6'
      end
    end

  end
end