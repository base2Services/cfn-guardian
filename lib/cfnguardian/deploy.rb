require 'aws-sdk-cloudformation'
require 'fileutils'
require 'cfnguardian/version'
require 'cfnguardian/log'
require 'cfnguardian/error'

module CfnGuardian
  class Deploy
    include Logging

    def initialize(opts,bucket,parameters,template_file,stack_name)
      @stack_name = stack_name
      @bucket = bucket
      @s3_path = "#{stack_name}/#{template_file}"
      @template_path = "out/#{template_file}"
      @template_url = "https://#{@bucket}.s3.amazonaws.com/#{@s3_path}"
      @parameters = parameters
      @changeset_role_arn = opts.fetch(:role_arn, nil)

      @tags = opts.fetch(:tags, {})
      if ENV.has_key?('CODEBUILD_RESOLVED_SOURCE_VERSION')
        tags[:'guardian:config:commit'] = ENV['CODEBUILD_RESOLVED_SOURCE_VERSION']
      end

      @client = Aws::CloudFormation::Client.new()
    end

    def upload_templates
      body = File.read(@template_path)
      client = Aws::S3::Client.new()
      client.put_object({
        body: body,
        bucket: @bucket,
        key: @s3_path
      })
    end

    # TODO: check for REVIEW_IN_PROGRESS
    def does_cf_stack_exist()
      begin
        resp = @client.describe_stacks({
          stack_name: @stack_name,
        })
      rescue Aws::CloudFormation::Errors::ValidationError
        return false
      end
      return resp.size > 0
    end

    def get_change_set_type()
      return does_cf_stack_exist() ? 'UPDATE' : 'CREATE'
    end

    def create_change_set()
      change_set_name = "#{@stack_name}-#{CfnGuardian::CHANGE_SET_VERSION}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
      change_set_type = get_change_set_type()

      if change_set_type == 'CREATE'
        params = get_parameters_from_template()
      else
        params = get_parameters_from_stack()
      end

      params.each do |param|
        if !@parameters[param[:parameter_key].to_sym].nil?
          param[:parameter_value] = @parameters[param[:parameter_key].to_sym]
          param[:use_previous_value] = false
        end
      end

      tags = get_tags()
      logger.debug "tagging stack with tags #{tags}"

      changeset_request = {
        stack_name: @stack_name,
        template_url: @template_url,
        capabilities: ["CAPABILITY_IAM"],
        parameters: params,
        tags: tags,
        change_set_name: change_set_name,
        change_set_type: change_set_type
      }

      unless @changeset_role_arn.nil?
        changeset_request[:role_arn] = @changeset_role_arn
      end

      logger.debug "Creating changeset"
      change_set = @client.create_change_set(changeset_request)
      return change_set, change_set_type
    end

    def wait_for_changeset(change_set_id)
      logger.debug "Waiting for changeset to be created"
      begin
        @client.wait_until :change_set_create_complete, change_set_name: change_set_id
      rescue Aws::Waiters::Errors::FailureStateError => e
        change_set = get_change_set(change_set_id)
        if change_set.status_reason.include?("The submitted information didn't contain changes.") || change_set.status_reason.include?("No updates are to be performed") && @ignore_empty_change_set
          raise CfnGuardian::EmptyChangeSetError, "No changes to deploy. Stack #{@stack_name} is up to date"
        else
          raise CfnGuardian::ChangeSetError, "Failed to create the changeset : #{e.message} Status: #{change_set.status} Reason: #{change_set.status_reason}"
        end
      end
    end

    def get_change_set(change_set_id)
      @client.describe_change_set({
        change_set_name: change_set_id,
      })
    end

    def execute_change_set(change_set_id)
      logger.debug "Executing the changeset"
      stack = @client.execute_change_set({
        change_set_name: change_set_id
      })
    end

    def wait_for_execute(change_set_type)
      waiter = change_set_type == 'CREATE' ? :stack_create_complete : :stack_update_complete
      logger.info "Waiting for changeset to #{change_set_type}"
      resp = @client.wait_until waiter, stack_name: @stack_name
    end

    def get_parameters_from_stack()
      resp = @client.get_template_summary({ stack_name: @stack_name })
      return resp.parameters.collect { |p| { parameter_key: p.parameter_key, use_previous_value: true }  }
    end

    def get_parameters_from_template()
      template_body = File.read(@template_path)
      resp = @client.get_template_summary({ template_body: template_body })
      return resp.parameters.collect { |p| { parameter_key: p.parameter_key, parameter_value: p.default_value }  }
    end

    def get_tags()
      default_tags = {
        'guardian:version': CfnGuardian::VERSION,
        Environment: 'guardian'
      }
      default_tags.merge!(@tags)
      tags = default_tags.map {|k,v| {key: k, value: v}}
      return tags
    end

  end
end
