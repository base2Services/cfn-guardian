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
        super
        @class = 'Http'
        @name = 'HttpCheck'
        @target = 'HttpCheckFunctionArn'
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

  end
end
