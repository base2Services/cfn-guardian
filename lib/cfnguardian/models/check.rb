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
        @package = 'aws-lambda-http-check'
        @handler = 'handler.main'
        @version = '0.1'
        @runtime = 'python3.6'
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
        @version = '0.2'
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
        @version = '0.1'
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
        @version = '0.1'
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
        @version = '0.1'
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
        @package = 'aws-lambda-ecs-container-instance-check'
        @handler = 'handler.run_check'
        @version = '0.1'
        @runtime = 'python3.6'
      end
    end

  end
end