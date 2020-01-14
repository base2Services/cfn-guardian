require 'yaml'
require 'cfndsl'
require 'tempfile'
require 'cfnguardian/string'
require 'cfnguardian/resources/base'
require 'cfnguardian/resources/ec2_instance'
require 'cfnguardian/resources/application_targetgroup'
require 'cfnguardian/resources/amazonmq'
require 'cfnguardian/resources/autoscaling_group'
require 'cfnguardian/resources/domain_expiry'
require 'cfnguardian/resources/ecs_cluster'
require 'cfnguardian/resources/http'
require 'cfnguardian/resources/nrpe'
require 'cfnguardian/resources/lambda'
require 'cfnguardian/resources/network_targetgroup'
require 'cfnguardian/resources/rds_cluster'
require 'cfnguardian/resources/rds_cluster_instance'
require 'cfnguardian/resources/rds_instance'
require 'cfnguardian/resources/redshift_cluster'
require 'cfnguardian/resources/sql'

module CfnGuardian
  class Compile
    include Logging
    
    attr_reader :cost
    
    def initialize(opts,bucket)
      @prefix = opts.fetch(:stack_name,'guardian')
      @bucket = bucket
      
      config = YAML.load_file(opts.fetch(:config))
      @resource_groups = config.fetch('Resources',{})
      @templates = config.fetch('Templates',{})
      
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
              logger.warn "'#{group}' is a unsupported resource group"
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
    
    def split_resources
      split = @resources.each_slice(190).to_a
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
      clean_out_directory
      resources = split_resources()
      stack_yaml = temp_file({stacks: @stacks, checks: @checks, network: @network})
      to_cloudformation('stacks.rb','guardian.compiled.yaml',stack_yaml)
      resources.each_with_index do |resources,index|
        yaml = temp_file({resources: resources})
        to_cloudformation('nested.rb',"guardian-stack-#{index}.compiled.yaml",yaml)
      end
    end
    
    def to_cloudformation(input,output,yaml)
      CfnDsl.disable_binding
      logger.debug("Compiling cfndsl template #{input} to YAML Cloudformation template #{output}")
      model = CfnDsl.eval_file_with_extras("lib/cfnguardian/templates/#{input}", [[:yaml, yaml]], false)
      template = JSON.parse(model.to_json).to_yaml
      File.write("out/#{output}", template)
    end
    
    def temp_file(resources)
      file = Tempfile.new(['cfn-guardian','.yaml'])
      file.write(resources.to_yaml)
      file.close
      return file.path
    end
    
    def clean_out_directory
      Dir["out/*.yaml"].each {|file| File.delete(file)}
    end
        
  end
end
