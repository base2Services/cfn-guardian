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
require 'cfnguardian/resources/dynamodb_table'
require 'cfnguardian/resources/ec2_instance'
require 'cfnguardian/resources/ecs_cluster'
require 'cfnguardian/resources/ecs_service'
require 'cfnguardian/resources/elastic_file_system'
require 'cfnguardian/resources/elasticache_replication_group'
require 'cfnguardian/resources/elastic_loadbalancer'
require 'cfnguardian/resources/http'
require 'cfnguardian/resources/internal_http'
require 'cfnguardian/resources/port'
require 'cfnguardian/resources/internal_port'
require 'cfnguardian/resources/nrpe'
require 'cfnguardian/resources/lambda'
require 'cfnguardian/resources/network_targetgroup'
require 'cfnguardian/resources/rds_cluster_instance'
require 'cfnguardian/resources/rds_instance'
require 'cfnguardian/resources/redshift_cluster'
require 'cfnguardian/resources/sql'
require 'cfnguardian/resources/sqs_queue'
require 'cfnguardian/resources/log_group'

module CfnGuardian
  class Compile
    include Logging
    
    attr_reader :cost, :resources, :topics
    
    def initialize(opts,bucket)
      @prefix = opts.fetch(:stack_name,'guardian')
      @bucket = bucket
      
      # Load in the alarms YAML config
      begin
        config = YAML.load_file(opts.fetch(:config))
      rescue
        logger.error("Failed to load config file #{opts.fetch(:config)}")
        exit 1
      end
      
      @resource_groups = config.fetch('Resources',{})
      @composites = config.fetch('Composites',{})
      @templates = config.fetch('Templates',{})
      @topics = config.fetch('Topics',{})
      @maintenance_groups = config.fetch('MaintenaceGroups', {})
      
      @maintenance_group_list = @maintenance_groups.keys.map {|group| "#{group}MaintenanceGroup"}
      @resources = []
      @stacks = []
      @checks = []
      
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
                resource_class = Kernel.const_get("CfnGuardian::Resource::#{@templates[group]['Inherit']}").new(resource)
                logger.debug "Inheritited resource group #{@templates[group]['Inherit']} for group #{group}"
              rescue NameError => e
                logger.warn "'#{@templates[group]['Inherit']}' resource group doesn't exist and is unable to be inherited from"
                next
              end
            else
              logger.error(e)
              next
            end
          end
          
          overides = @templates.has_key?(group) ? @templates[group] : {}
          @resources.concat resource_class.get_alarms(overides)
          @resources.concat resource_class.get_metric_filters()
          @resources.concat resource_class.get_events()
          @checks.concat resource_class.get_checks()

          @cost += resource_class.get_cost
        end
      end
      
      @maintenance_groups.each do |maintenance_group,resource_groups|
        resource_groups.each do |group, alarms|
          alarms.each do |alarm, resources|
            resources.each do |resource|
              res = @resources.find {|r| 
                (r.type == 'Alarm') && 
                (r.class == group && r.name == alarm) &&
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
    end
    
    def alarms
      @resources.select{|h| h[:type] == 'Alarm'}
    end
    
    def split_resources
      split = @resources.each_slice(200).to_a
      split.each_with_index do |resources,index|
        @stacks.push({
          'Name' => "GuardianStack#{index}",
          'TemplateURL' => "https://#{@bucket}.s3.amazonaws.com/#{@prefix}/guardian-stack-#{index}.compiled.yaml",
          'Reference' => index
        })
      end
      return split
    end
    
    def compile_templates
      clean_out_directory()
      resources = split_resources()
      
      main_stack = CfnGuardian::Stacks::Main.new()
      template = main_stack.build_template(@stacks,@checks,@topics,@maintenance_group_list)
      valid = template.validate
      FileUtils.mkdir_p 'out'
      File.write("out/guardian.compiled.yaml", JSON.parse(valid.to_json).to_yaml)
      
      resources.each_with_index do |resources,index|
        stack = CfnGuardian::Stacks::Resources.new()
        template = stack.build_template(resources,@maintenance_group_list)
        valid = template.validate
        File.write("out/guardian-stack-#{index}.compiled.yaml", JSON.parse(valid.to_json).to_yaml)
      end
    end
    
    def clean_out_directory
      Dir["out/*.yaml"].each {|file| File.delete(file)}
    end
        
  end
end
