require 'cfnguardian/string'

module CfnGuardian
  module Models
    class Event
      
      attr_reader :type
      attr_accessor :class,
        :target,
        :hash,
        :name,
        :cron,
        :enabled,
        :resource,
        :required
      
      def initialize(resource)
        @type = 'Event'
        @class = nil
        @target = nil
        @hash = Digest::MD5.hexdigest resource['Id']
        @name = @hash
        @cron = "* * * * ? *"
        @enabled = true
        @resource = resource['Id'].to_resource_name
        @required = %w()
      end
      
      def to_h
        return {
          type: @type,
          class: @class,
          target: @target,
          hash: @hash,
          name: @name,
          cron: @cron,
          enabled: @enabled,
          resource: @resource,
          payload: event_payload()
        }
      end
      
      def event_payload
        {}.to_json
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
        @class = 'Http'
        @name = 'HttpEvent'
        @target = 'HttpCheckFunction'
        @endpoint = resource['Id']
        @method = resource.fetch('Method','GET')
        @timeout = resource.fetch('Timeout',120)
        @status_code = resource.fetch('StatusCode',200)
        @body_regex = resource.fetch('BodyRegex',nil)
        @headers = resource.fetch('Headers',nil)
        @payload = resource.fetch('Payload',nil)
      end
      
      def event_payload
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
    
    class NrpeEvent < Event
      def initialize(resource,environment,command)
        super(resource)
        @class = 'Nrpe'
        @name = 'NrpeEvent'
        @target = "NrpeCheckFunction#{environment}"
        @host = resource['Id']
        @environment = environment
        @region = resource.fetch('Region',"${AWS::Region}")
        @command = command
      end
      
      def event_payload
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
        @class = 'Ssl'
        @name = 'SslEvent'
        @target = 'SslCheckFunction'
        @cron = "0 12 * * ? *" 
        @url = resource['Id']
        @region = resource.fetch('Region',"${AWS::Region}")
      end
      
      def event_payload
        return {
          'Url' => @url,
          'Region' => @region
        }.to_json
      end
    end
    
    class DnsEvent < Event
      
      attr_accessor :domain,
        :region
      
      def initialize(resource)
        super(resource)
        @class = 'Dns'
        @name = 'DnsEvent'
        @target = 'DnsCheckFunction'
        @cron = "0 12 * * ? *" 
        @domain = resource['Id']
        @region = resource.fetch('Region',"${AWS::Region}")
      end
      
      def event_payload
        {'Domain' => @domain}.to_json
      end
    end
    
    class SqlEvent < Event
      def initialize(resource)
        super(resource)
        @class = 'Sql'
        @name = 'SqlEvent'
        @target = 'SqlCheckFunction'
        @host = resource['Id']
        @engine = resource['Engine']
        @port = resource['Port']
        @ssm_username = resource['SSMUsername']
        @ssm_password = resource['SSMPassword']
        @query = resource['Query']
        @region = resource.fetch('Region',"${AWS::Region}")
        @test_type = '1-row-1-value-zero-is-good'
      end
      
      def event_payload
        return {
          'Host' => @host,
          'Engine' => @engine,
          'Port' => @port,
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
        @class = 'ContainerInstance'
        @name = 'ContainerInstanceEvent'
        @target = 'ContainerInstanceCheckFunction'
        @cron = "0/5 * * * ? *"
        @cluster = resource['Id']
      end
      
      def event_payload
        {'CLUSTER' => @cluster}.to_json
      end
    end

  end
end
