require 'cfnguardian/string'

module CfnGuardian
  module Models
    class Check
      
      attr_reader :type
      attr_accessor :group,
        :name,
        :package,
        :handler,
        :version,
        :runtime,
        :environment,
        :subnets, 
        :vpc
        
      def initialize(resource)
        @type = 'Check'
        @group = nil
        @name = nil
        @package = nil
        @handler = nil
        @version = nil
        @runtime = nil
        @environment = ''
        @subnets = nil
        @vpc = nil
      end
    end
    
    class HttpCheck < Check      
      def initialize(resource)
        super(resource)
        @group = 'Http'
        @name = 'HttpCheck'
        @package = 'http-check'
        @handler = 'handler.http_check'
        @version = '0bc33e51abb1f27729ecb170611bf6b440e71a0e'
        @runtime = 'python3.7'
      end
    end
    
    class InternalHttpCheck < HttpCheck
      def initialize(resource)
        super(resource)
        @group = 'InternalHttp'
        @name = 'InternalHttpCheck'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end
    
    class PortCheck < Check      
      def initialize(resource)
        super(resource)
        @group = 'Port'
        @name = 'PortCheck'
        @package = 'port-check'
        @handler = 'handler.port_check'
        @version = '356203b2a720ba0730622f978e677b88f8d0c328'
        @runtime = 'python3.6'
      end
    end
    
    class InternalPortCheck < PortCheck
      def initialize(resource)
        super(resource)
        @group = 'InternalPort'
        @name = 'InternalPortCheck'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end
    
    class NrpeCheck < Check
      def initialize(resource)
        super(resource)
        @group = 'Nrpe'
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
        @group = 'Ssl'
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
        @group = 'DomainExpiry'
        @name = 'DomainExpiryCheck'
        @package = 'aws-lambda-dns-check'
        @handler = 'main'
        @version = '9db96ca32379faddc47e55849b7e296b7b70a48e'
        @runtime = 'go1.x'
      end
    end
    
    class SqlCheck < Check
      def initialize(resource)
        super(resource)
        @group = 'Sql'
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
        @group = 'ContainerInstance'
        @name = 'ContainerInstanceCheck'
        @package = 'ecs-containder-instance-check'
        @handler = 'handler.run_check'
        @version = '4f650d5846d6e8d19f0139bccdeeb147f03f0dd6'
        @runtime = 'python3.6'
      end
    end
    
    class TLSCheck < Check
      def initialize(resource)
        super(resource)
        @group = 'TLS'
        @name = 'TLSCheck'
        @package = 'tls-version-check'
        @handler = 'handler.run_check'
        @version = 'de83afdde0d976364af37ad7552a8496c3c94ab5'
        @runtime = 'python3.7'
      end
    end
    
    class SFTPCheck < Check
      def initialize(resource)
        super(resource)
        @group = 'SFTP'
        @name = 'SFTPCheck'
        @package = 'sftp-check'
        @handler = 'handler.sftp_check'
        @version = '987e71f2607347e13e3f156535059d6d3ce1ceed'
        @runtime = 'python3.7'
      end
    end
    
    class InternalSFTPCheck < SFTPCheck
      def initialize(resource)
        super(resource)
        @group = 'InternalSFTP'
        @name = 'InternalSFTPCheck'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end

  end
end