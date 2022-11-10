require 'cfnguardian/string'

module CfnGuardian
  module Models
    class BaseEvent
      
      attr_reader :type
      attr_accessor :group,
        :target,
        :hash,
        :name,
        :cron,
        :enabled,
        :resource,
        :environment,
        :payload,
        :ssm_parameters
      
      def initialize(resource)
        @type = 'Event'
        @group = nil
        @target = nil
        @hash = Digest::MD5.hexdigest resource['Id']
        @name = @hash
        @cron = "* * * * ? *"
        @enabled = true
        @resource = resource['Id'].to_resource_name
        @environment = ""
        @payload = {}.to_json
        @ssm_parameters = []
      end      
    end

    class HttpEvent < BaseEvent
      
      attr_accessor :endpoint,
        :method,
        :timeout,
        :status_code,
        :body_regex,
        :headers,
        :payload
      
      def initialize(resource)
        super(resource)
        @group = 'Http'
        @name = 'HttpEvent'
        @target = 'HttpCheckFunction'
        @endpoint = resource['Id']
        @method = resource.fetch('Method','GET')
        @timeout = resource.fetch('Timeout',50)
        @status_code = resource.fetch('StatusCode',200)
        @body_regex = resource.fetch('BodyRegex',nil)
        @headers = resource.fetch('Headers',nil)
        @user_agent = resource.fetch('UserAgent',nil)
        @payload = resource.fetch('Payload',nil)
        @compressed = resource.fetch('Compressed',false)
      end
      
      def payload
        payload = {
          'ENDPOINT' => @endpoint,
          'METHOD' => @method,
          'TIMEOUT' => @timeout,
          'STATUS_CODE_MATCH' => @status_code
        }
        payload['BODY_REGEX_MATCH'] = @body_regex unless @body_regex.nil?
        payload['HEADERS'] = @headers unless @headers.nil?
        payload['USER_AGENT'] = @user_agent unless @user_agent.nil?
        payload['PAYLOAD'] = @payload unless @payload.nil?
        payload['COMPRESSED'] = '1' if @compressed
        return payload.to_json
      end
    end

    class WebSocketEvent < BaseEvent
      
      attr_accessor :endpoint,
        :message,
        :expected_response,
        :timeout,
        :payload
      
      def initialize(resource)
        super(resource)
        @group = 'WebSocket'
        @name = 'WebSocketEvent'
        @target = 'WebSocketCheckFunction'
        @endpoint = resource['Id']
        @message = resource.fetch('Message',nil)
        @expected_response = resource.fetch('Expected_Response',nil)
        @timeout = resource.fetch('Timeout',50)
        @payload = resource.fetch('Payload',nil)
      end
      
      def payload
        payload = {
          'ENDPOINT' => @endpoint,
          'MESSAGE' => @message,
          'EXPECTED_RESPONSE' => @expected_response
        }
        payload['PAYLOAD'] = @payload unless @payload.nil?
        return payload.to_json
      end
    end
    
    class InternalHttpEvent < HttpEvent      
      def initialize(resource,environment)
        super(resource)
        @group = 'InternalHttp'
        @name = 'InternalHttpEvent'
        @target = "InternalHttpCheckFunction#{environment}"
        @environment = environment
      end
    end
    
    class PortEvent < BaseEvent      
      def initialize(resource)
        super(resource)
        @group = 'Port'
        @name = 'PortEvent'
        @target = 'PortCheckFunction'
        @hostname = resource['Id']
        @port = resource['Port']
        @timeout = resource.fetch('Timeout',120)
      end
      
      def payload
        return {
          'HOSTNAME' => @hostname,
          'PORT' => @port,
          'TIMEOUT' => @timeout,
          'STATUS_CODE_MATCH' => @status_code
        }.to_json
      end
    end
    
    class InternalPortEvent < PortEvent    
      def initialize(resource,environment)
        super(resource)
        @group = 'InternalPort'
        @name = 'InternalPortEvent'
        @target = "InternalPortCheckFunction#{environment}"
        @environment = environment
      end
    end
    
    class NrpeEvent < BaseEvent      
      def initialize(resource,environment,command)
        super(resource)
        @group = 'Nrpe'
        @name = 'NrpeEvent'
        @target = "NrpeCheckFunction#{environment}"
        @host = resource['Id']
        @environment = environment
        @region = resource.fetch('Region',"${AWS::Region}")
        @hash = Digest::MD5.hexdigest "#{resource['Id']}#{command}"
        @command = command
      end
      
      def payload
        return {
          'host' => @host,
          'environment' => @environment,
          'region' => @region,
          'cmd' => @command
        }.to_json
      end
    end
    
    class SslEvent < BaseEvent
      def initialize(resource)
        super(resource)
        @group = 'Ssl'
        @name = 'SslEvent'
        @target = 'SslCheckFunction'
        @cron = resource.fetch('Schedule', "0 12 * * ? *")
        @url = resource['Id']
        @region = resource.fetch('Region',"${AWS::Region}")
      end
      
      def payload
        return {
          'Url' => @url,
          'Region' => @region
        }.to_json
      end
    end
    
    class InternalSslEvent < SslEvent    
      def initialize(resource,environment)
        super(resource)
        @group = 'InternalSsl'
        @name = 'InternalSslEvent'
        @target = "InternalSslCheckFunction#{environment}"
        @environment = environment
      end
    end
    
    class DomainExpiryEvent < BaseEvent
      
      attr_accessor :domain,
        :region
      
      def initialize(resource)
        super(resource)
        @group = 'DomainExpiry'
        @name = 'DomainExpiryEvent'
        @target = 'DomainExpiryCheckFunction'
        @cron = resource.fetch('Schedule', "0 12 * * ? *")
        @domain = resource['Id']
        @region = resource.fetch('Region',"${AWS::Region}")
      end
      
      def payload
        return {'Domain' => @domain}.to_json
      end
    end
    
    class SqlEvent < BaseEvent
      def initialize(resource,query,environment)
        super(resource)
        @group = 'Sql'
        @name = 'SqlEvent'
        @target = "SqlCheckFunction#{environment}"
        @host = resource['Id']
        @engine = resource['Engine']
        @port = resource['Port']
        @ssm_username = resource['SSMUsername']
        @ssm_password = resource['SSMPassword']
        @query = query
        @region = resource.fetch('Region',"${AWS::Region}")
        @test_type = '1-row-1-value-zero-is-good'
        @environment = environment
      end
      
      def payload
        return {
          'Host' => @host,
          'Engine' => @engine,
          'Port' => @port,
          'SqlCall' => @query,
          'SSMUsername' => @ssm_username,
          'SSMPassword' => @ssm_password,
          'Region' => @region,
          'TestType' => @test_type
        }.to_json
      end
      
      def ssm_parameters
        params = []
        params << @ssm_username
        params << @ssm_password
        return params
      end
    end
    
    class ContainerInstanceEvent < BaseEvent
      def initialize(resource)
        super(resource)
        @group = 'ContainerInstance'
        @name = 'ContainerInstanceEvent'
        @target = 'ContainerInstanceCheckFunction'
        @cron = resource.fetch('Schedule', "0/5 * * * ? *")
        @cluster = resource['Id']
      end
      
      def payload
        return {'CLUSTER' => @cluster}.to_json
      end
    end
    
    class SFTPEvent < BaseEvent
      def initialize(resource)
        super(resource)
        @group = 'SFTP'
        @name = 'SFTPEvent'
        @target = 'SFTPCheckFunction'
        @cron = resource.fetch('Schedule', "0/5 * * * ? *")
        @host = resource['Id']
        @user = resource['User']
        @port = resource.fetch('Port', nil)
        @server_key = resource.fetch('ServerKey', nil)
        @password = resource.fetch('Password', nil)
        @private_key = resource.fetch('PrivateKey', nil)
        @private_key_pass = resource.fetch('PrivateKeyPass', nil)
        @file = resource.fetch('File', nil)
        @file_regex_match = resource.fetch('FileRegexMatch', nil)
      end
      
      def payload
        payload = {
          'HOSTNAME' => @host,
          'USERNAME' => @user
        }
        payload['PORT'] = @port unless @port.nil?
        payload['SERVER_KEY'] = @server_key unless @server_key.nil?
        payload['PASSWORD'] = @password unless @password.nil?
        payload['PRIVATEKEY'] = @private_key unless @private_key.nil?
        payload['PRIVATEKEY_PASSWORD'] = @private_key_pass unless @private_key_pass.nil?
        payload['FILE'] = @file unless @file.nil?
        payload['FILE_REGEX_MATCH'] = @file_regex_match unless @file_regex_match.nil?
        return payload.to_json
      end
      
      def ssm_parameters
        params = []
        params << @password unless @password.nil?
        params << @private_key unless @private_key.nil?
        params << @private_key_pass unless @private_key_pass.nil?
        return params
      end
    end
    
    class InternalSFTPEvent < SFTPEvent    
      def initialize(resource,environment)
        super(resource)
        @group = 'InternalSFTP'
        @name = 'InternalSFTPEvent'
        @target = "InternalSFTPCheckFunction#{environment}"
        @environment = environment
      end
    end
    
    class TLSEvent < BaseEvent
      def initialize(resource)
        super(resource)
        @group = 'TLS'
        @name = 'TLSEvent'
        @target = 'TLSCheckFunction'
        @cron = resource.fetch('Schedule', "0/5 * * * ? *")
        @host = resource['Id']
        @port = resource.fetch('Port', 443)
        @check_max = resource.fetch('MaxSupported', nil)
        @versions =  resource.fetch('Versions', ['SSLv2','SSLv3','TLSv1','TLSv1.1','TLSv1.2'])
      end
      
      def payload
        payload = {
          'HOSTNAME' => @host,
          'PORT' => @port
        }
        payload['CHECK_MAX_SUPPORTED'] = @check_max.nil?
        payload['PROTOCOLS'] = @versions unless @versions.nil?
        return payload.to_json
      end
    end

    class AzureFileEvent < BaseEvent
      def initialize(resource)
        super(resource)
        @group = 'AzureFile'
        @name = 'AzureFileEvent'
        @target = 'AzureFileCheckFunction'
        @cron = resource.fetch('Schedule', "0/5 * * * ? *")
        @storage_account = resource['Id']
        @container = resource['Container']
        @connection_string = resource['ConnectionString']
        @search = resource['Search']
      end

      def payload
        return {
          'STORAGE_ACCOUNT' => @storage_account,
          'CONTAINER' => @container,
          'CONNECTION_STRING' => @connection_string,
          'SEARCH' => @search
        }.to_json
      end

      def ssm_parameters
        return [@connection_string]
      end
    end

  end
end
