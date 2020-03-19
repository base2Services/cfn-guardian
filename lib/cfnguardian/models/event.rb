require 'cfnguardian/string'

module CfnGuardian
  module Models
    class Event
      
      attr_reader :type
      attr_accessor :group,
        :target,
        :hash,
        :name,
        :cron,
        :enabled,
        :resource,
        :environment,
        :payload
      
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
      end      
    end
    
    class HttpEvent < Event
      
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
        @payload = resource.fetch('Payload',nil)
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
        payload['PAYLOAD'] = @payload unless @payload.nil?
        return payload.to_json
      end
    end
    
    class InternalHttpEvent < HttpEvent      
      def initialize(resource,environment)
        super(resource)
        @group = 'InternalHttp'
        @target = "InternalHttpCheckFunction#{environment}"
        @environment = environment
      end
    end
    
    class PortEvent < Event      
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
        @target = "InternalPortCheckFunction#{environment}"
        @environment = environment
      end
    end
    
    class NrpeEvent < Event      
      def initialize(resource,environment,command)
        super(resource)
        @group = 'Nrpe'
        @name = 'NrpeEvent'
        @target = "NrpeCheckFunction#{environment}"
        @host = resource['Id']
        @environment = environment
        @region = resource.fetch('Region',"${AWS::Region}")
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
    
    class SslEvent < Event
      def initialize(resource)
        super(resource)
        @group = 'Ssl'
        @name = 'SslEvent'
        @target = 'SslCheckFunction'
        @cron = "0 12 * * ? *" 
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
    
    class DomainExpiryEvent < Event
      
      attr_accessor :domain,
        :region
      
      def initialize(resource)
        super(resource)
        @group = 'DomainExpiry'
        @name = 'DomainExpiryEvent'
        @target = 'DomainExpiryCheckFunction'
        @cron = "0 12 * * ? *" 
        @domain = resource['Id']
        @region = resource.fetch('Region',"${AWS::Region}")
      end
      
      def payload
        return {'Domain' => @domain}.to_json
      end
    end
    
    class SqlEvent < Event
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
    end
    
    class ContainerInstanceEvent < Event
      def initialize(resource)
        super(resource)
        @group = 'ContainerInstance'
        @name = 'ContainerInstanceEvent'
        @target = 'ContainerInstanceCheckFunction'
        @cron = "0/5 * * * ? *"
        @cluster = resource['Id']
      end
      
      def payload
        return {'CLUSTER' => @cluster}.to_json
      end
    end

  end
end
