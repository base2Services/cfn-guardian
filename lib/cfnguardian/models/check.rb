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
        :timeout,
        :branch
        
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
        @branch = "master"
      end
    end
    
    class HttpCheck < BaseCheck      
      def initialize(resource)
        super(resource)
        @group = 'Http'
        @name = 'HttpCheck'
        @package = 'http-check'
        @handler = 'handler.http_check'
        @version = '077c726ed691a1176caf95497b8b02f05f00e0cb'
        @runtime = 'python3.11'
      end
    end
    class WebSocketCheck < BaseCheck      
      def initialize(resource)
        super(resource)
        @group = 'WebSocket'
        @name = 'WebSocketCheck'
        @package = 'websocket-check'
        @handler = 'handler.websocket_check'
        @version = 'bb0125e878e127028dfb3d4a0de93e580e77305e'
        @runtime = 'python3.11'
        @branch = 'main'
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
        @version = 'd773db7333fddea1f4e1781f9906bb05c363dd42'
        @runtime = 'python3.11'
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
        @package = 'ecs-container-instance-check'
        @handler = 'handler.run_check'
        @version = '5cb604acccd0823c74b21e83d7e40612ef38e313'
        @runtime = 'python3.11'
      end
    end
    
    class TLSCheck < BaseCheck
      def initialize(resource)
        super(resource)
        @group = 'TLS'
        @name = 'TLSCheck'
        @package = 'tls-version-check'
        @handler = 'handler.run_check'
        @version = '2b4fcbf55e266e793ee06e72013ed098f4eb2c0a'
        @runtime = 'python3.11'
      end
    end
    
    class SFTPCheck < BaseCheck
      def initialize(resource)
        super(resource)
        @group = 'SFTP'
        @name = 'SFTPCheck'
        @package = 'sftp-check'
        @handler = 'handler.sftp_check'
        @version = '03e934328939cd87e5fb41fb01d6a690a94dc94c'
        @runtime = 'python3.11'
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
        @version = '6a5abdbed4408592a3045638a1a5a74c89a37e12'
        @runtime = 'python3.11'
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
        @version = '5e880ffc7d0c478383fa353e28fe3e9f8310a93c'
        @runtime = 'python3.11'
      end 
    end

  end
end
