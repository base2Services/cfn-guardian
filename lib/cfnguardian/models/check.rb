require 'cfnguardian/string'

module CfnGuardian
  module Models
    class BaseCheck
      
      attr_reader :type
      attr_accessor :group,
        :name,
        :package,
        :handler,
        :version,
        :runtime,
        :environment,
        :subnets, 
        :vpc,
        :memory,
        :timeout
        
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
        @memory = 128
        @timeout = 120
      end
    end
    
    class HttpCheck < BaseCheck      
      def initialize(resource)
        super(resource)
        @group = 'Http'
        @name = 'HttpCheck'
        @package = 'http-check'
        @handler = 'handler.http_check'
        @version = '0e945240f9d93242f807e86d1a9b3383a1764b96'
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
    
    class PortCheck < BaseCheck      
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
    
    class NrpeCheck < BaseCheck
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
    
    class SslCheck < BaseCheck
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
    
    class InternalSslCheck < SslCheck
      def initialize(resource)
        super(resource)
        @group = 'InternalSsl'
        @name = 'InternalSslCheck'
        @subnets = resource['Subnets']
        @vpc = resource['VpcId']
        @environment = resource['Environment']
      end
    end
    
    class DomainExpiryCheck < BaseCheck
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
    
    class SqlCheck < BaseCheck
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
    
    class ContainerInstanceCheck < BaseCheck
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
    
    class TLSCheck < BaseCheck
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
    
    class SFTPCheck < BaseCheck
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

    class AzureFileCheck < BaseCheck
      def initialize(resource)
        super(resource)
        @group = 'AzureFile'
        @name = 'AzureFileCheck'
        @package = 'azure-file-check'
        @handler = 'handler.file_check'
        @version = 'cc37aa8fe4855570132431611b507274b390f4c1'
        @runtime = 'python3.7'
        @memory = 256
        @timeout = 600
      end
    end

    class MaintenanceGroupCheck < BaseCheck
      def initialize(resource)
        super(resource)
        @name = 'MaintenanceGroupCheck'
        @package = 'maintenance-group-check'
        @handler = 'handler.maintenance_group_check'
        @version = '5b795e6509068d1767e4be80f2e6868cbeb3b425'
        @runtime = 'python3.7'
      end 
    end

  end
end
