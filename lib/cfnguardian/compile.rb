require 'yaml'
require 'fileutils'
require 'cfnguardian/string'
require 'cfnguardian/stacks/resources'
require 'cfnguardian/stacks/main'
require 'cfnguardian/models/composite'
require 'cfnguardian/resources/base'
require 'cfnguardian/resources/apigateway'
require 'cfnguardian/resources/application_targetgroup'
require 'cfnguardian/resources/amazonmq_broker'
require 'cfnguardian/resources/autoscaling_group'
require 'cfnguardian/resources/cloudfront_distribution'
require 'cfnguardian/resources/autoscaling_group'
require 'cfnguardian/resources/domain_expiry'
require 'cfnguardian/resources/dms_task'
require 'cfnguardian/resources/dms_cluster'
require 'cfnguardian/resources/documentdb_cluster'
require 'cfnguardian/resources/dynamodb_table'
require 'cfnguardian/resources/ec2_instance'
require 'cfnguardian/resources/ecs_cluster'
require 'cfnguardian/resources/ecs_service'
require 'cfnguardian/resources/eks_container_insights'
require 'cfnguardian/resources/elastic_file_system'
require 'cfnguardian/resources/elasticache_replication_group'
require 'cfnguardian/resources/elastic_loadbalancer'
require 'cfnguardian/resources/http'
require 'cfnguardian/resources/websocket'
require 'cfnguardian/resources/internal_http'
require 'cfnguardian/resources/port'
require 'cfnguardian/resources/internal_port'
require 'cfnguardian/resources/nrpe'
require 'cfnguardian/resources/lambda'
require 'cfnguardian/resources/network_targetgroup'
require 'cfnguardian/resources/rds_cluster'
require 'cfnguardian/resources/rds_cluster_instance'
require 'cfnguardian/resources/rds_instance'
require 'cfnguardian/resources/redshift_cluster'
require 'cfnguardian/resources/sql'
require 'cfnguardian/resources/sqs_queue'
require 'cfnguardian/resources/log_group'
require 'cfnguardian/resources/sftp'
require 'cfnguardian/resources/internal_sftp'
require 'cfnguardian/resources/tls'
require 'cfnguardian/resources/azure_file'
require 'cfnguardian/resources/amazonmq_rabbitmq'
require 'cfnguardian/resources/batch'
require 'cfnguardian/resources/glue'
require 'cfnguardian/resources/step_functions'
require 'cfnguardian/resources/vpn_tunnel'
require 'cfnguardian/resources/vpn_connection'
require 'cfnguardian/resources/elastic_search'
require 'cfnguardian/resources/jenkins'
require 'cfnguardian/version'
require 'cfnguardian/error'


module CfnGuardian
  class Compile
    include Logging
    
    attr_reader :cost, :resources, :topics, :global_tags
    
    def initialize(config_file)
      config = YAML.load_file(config_file)
            
      @resource_groups = config.fetch('Resources',{})
      @composites = config.fetch('Composites',{})
      @templates = config.fetch('Templates',{})
      @topics = config.fetch('Topics',{})
      @maintenance_groups = config.fetch('MaintenanceGroups', {})
      @event_subscriptions = config.fetch('EventSubscriptions', {})
      @global_tags = config.fetch('GlobalTags', {})
      
      # Make sure the default topics exist if they aren't supplied in the alarms.yaml
      %w(Critical Warning Task Informational Events).each do |topic|
        @topics[topic] = '' unless @topics.has_key?(topic)
      end

      @resources = []
      @stacks = []
      @checks = []
      @ssm_parameters = []
      
      @cost = 0
    end
    
    def get_resources
      @resource_groups.each do |group,resources|
        resources.each do |resource|
          
          begin
            resource_class = Kernel.const_get("CfnGuardian::Resource::#{group}").new(resource)
          rescue NameError => e
            if @templates.has_key?(group) && @templates[group].has_key?('Inherit')
              begin
                resource_class = Kernel.const_get("CfnGuardian::Resource::#{@templates[group]['Inherit']}").new(resource, group)
                logger.debug "Inherited resource group #{@templates[group]['Inherit']} for group #{group}"
              rescue NameError => e
                logger.warn "'#{@templates[group]['Inherit']}' resource group doesn't exist and is unable to be inherited from"
                next
              end
            else
              logger.error(e)
              next
            end
          end
          
          template_overides = @templates.has_key?(group) ? @templates[group] : {}
          @resources.concat resource_class.get_alarms(group,template_overides)

          @resources.concat resource_class.get_metric_filters()
          @resources.concat resource_class.get_events()

          event_subscriptions = @event_subscriptions.has_key?(group) ? @event_subscriptions[group] : {}
          @resources.concat resource_class.get_event_subscriptions(group,event_subscriptions)
          
          @checks.concat resource_class.get_checks()

          @cost += resource_class.get_cost
        end
      end
      
      @maintenance_groups.each do |maintenance_group,resource_groups|
        resource_groups.each do |group, alarms|
          if group == 'Schedules' 
            next
          end
          alarms.each do |alarm, resources|
            resources.each do |resource|

              res = @resources.find {|r| 
                (r.type == 'Alarm') && 
                (r.group == group && r.name == alarm) &&
                (r.resource_id == resource['Id'] || r.resource_name == resource['Name'])}

              unless res.nil?
                res.maintenance_groups.append("#{maintenance_group}MaintenanceGroup")
              end
              
            end
          end
        end
      end
      
      @composites.each do |name,params|
        @resources.push CfnGuardian::Models::Composite.new(name,params)
        @cost += 0.50
      end
      
      @ssm_parameters = @resources.select {|resource| resource.type == 'Event'}.map {|event| event.ssm_parameters}.flatten.uniq

      validate_resources()
    end
    
    def alarms
      @resources.select {|resource| resource.type == 'Alarm'}
    end

    def validate_resources()
      errors = []
      @resources.each do |resource|
        case resource.type
        when 'Alarm'
          %w(metric_name namespace).each do |property|
            if resource.send(property).nil?
              errors << "Alarm #{resource.name} for resource #{resource.resource_id} has nil value for property #{property.to_camelcase}. This could be due to incorrect spelling of a default alarm name or missing property #{property.to_camelcase} on a new alarm."
            end
          end
        when 'Check'
          # no validation check yet
        when 'Event'
          # no validation check yet
        when 'Composite'
          # no validation check yet
        when 'EventSubscription'
          # no validation check yet
        when 'MetricFilter'
          # no validation check yet
        end
      end

      raise CfnGuardian::ValidationError, "#{errors.size} errors found\n[*] #{errors.join("\n[*] ")}" if errors.any?
    end
    
    def compile_templates(template_file)      
      main_stack = CfnGuardian::Stacks::Main.new()
      main_stack.build_template(@stacks,@checks,@topics,@maintenance_groups,@ssm_parameters)
      
      resource_stack = CfnGuardian::Stacks::Resources.new(main_stack.template)
      resource_stack.build_template(@resources)

      valid = main_stack.template.validate
      FileUtils.mkdir_p 'out'
      File.write("out/#{template_file}", JSON.parse(valid.to_json).to_yaml)
    end

    def load_parameters(options)
      parameters = {}
      # Load sns topic parameters in order of preference
      @topics.each do |key, value|
        # if parameter is passed in as a command line option
        if options.has_key?("sns_#{key.downcase}")
          parameters[key.to_sym] = options["sns_#{key.downcase}"]
        # if parameter is in config
        elsif !value.empty?
          parameters[key.to_sym] = value
        # if parameter is set as environment variable
        elsif ENV.has_key?("GUARDIAN_TOPIC_#{key.upcase}")
          parameters[key.to_sym] = ENV["GUARDIAN_TOPIC_#{key.upcase}"]
        end
      end

      return parameters
    end

    def genrate_template_config(parameters)
      template = {
        Tags: {
          'guardian:version': CfnGuardian::VERSION
        }
      }

      if ENV.has_key?('CODEBUILD_RESOLVED_SOURCE_VERSION')
        template[:Tags][:'guardian:config:commit'] = ENV['CODEBUILD_RESOLVED_SOURCE_VERSION']
      end

      unless parameters.empty?
        template[:Parameters] = parameters
      end

      File.write("out/template-config.guardian.json", template.to_json)
    end
        
  end
end
