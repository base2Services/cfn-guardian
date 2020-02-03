require 'yaml'
require 'fileutils'
require 'cfnguardian/string'
require 'cfnguardian/stacks/resources'
require 'cfnguardian/stacks/main'
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
require 'cfnguardian/resources/nrpe'
require 'cfnguardian/resources/lambda'
require 'cfnguardian/resources/network_targetgroup'
require 'cfnguardian/resources/rds_cluster_instance'
require 'cfnguardian/resources/rds_instance'
require 'cfnguardian/resources/redshift_cluster'
require 'cfnguardian/resources/sql'
require 'cfnguardian/resources/sqs_queue'

module CfnGuardian
  class Compile
    include Logging
    
    attr_reader :cost, :resources, :topics
    
    def initialize(opts,bucket)
      @prefix = opts.fetch(:stack_name,'guardian')
      @bucket = bucket
      
      config = YAML.load_file(opts.fetch(:config))
      @resource_groups = config.fetch('Resources',{})
      @templates = config.fetch('Templates',{})
      @topics = config.fetch('Topics',{})
      
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
          @resources.concat resource_class.get_events()
          @checks.concat resource_class.get_checks()

          @cost += resource_class.get_cost
        end
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
      template = main_stack.build_template(@stacks,@checks)
      valid = template.validate
      FileUtils.mkdir_p 'out'
      File.write("out/guardian.compiled.yaml", JSON.parse(valid.to_json).to_yaml)
      
      resources.each_with_index do |resources,index|
        stack = CfnGuardian::Stacks::Resources.new()
        template = stack.build_template(resources)
        valid = template.validate
        File.write("out/guardian-stack-#{index}.compiled.yaml", JSON.parse(valid.to_json).to_yaml)
      end
    end
    
    def clean_out_directory
      Dir["out/*.yaml"].each {|file| File.delete(file)}
    end
        
  end
end
