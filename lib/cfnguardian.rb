require 'thor'
require 'terminal-table'
require "cfnguardian/log"
require "cfnguardian/version"
require "cfnguardian/compile"
require "cfnguardian/validate"
require "cfnguardian/deploy"

module CfnGuardian
  class Cli < Thor
    include Logging
    
    map %w[--version -v] => :__print_version
    desc "--version, -v", "print the version"
    def __print_version
      puts CfnGuardian::VERSION
    end
    
    desc "compile", "Generate monitoring CloudFormation templates"
    long_desc <<-LONG
    Generates CloudFormation templates from the alarm configuration and output to the out/ directory.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file", required: true
    method_option :validate, type: :boolean, default: true, desc: "validate cfn templates"
    method_option :bucket, type: :string, desc: "provide custom bucket name, will create a default bucket if not provided"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"

    def compile
      set_region(options[:region],options[:validate])
      s3 = CfnGuardian::S3.new(options[:bucket])
      
      compiler = CfnGuardian::Compile.new(options,s3.bucket)
      compiler.get_resources
      compiler.compile_templates
      logger.info "Clouformation templates compiled successfully in out/ directory"
      if options[:validate]
        s3.create_bucket_if_not_exists()
        validator = CfnGuardian::Validate.new(s3.bucket)
        if validator.validate
          logger.error("One or more templates failed to validate")
          exit(1)
        else
          logger.info "Clouformation templates were validated successfully"
        end
      end
      logger.warn "AWS cloudwatch alarms defined in the templates will cost roughly $#{'%.2f' % compiler.cost} per month"
    end

    desc "deploy", "Generates and deploys monitoring CloudFormation templates"
    long_desc <<-LONG
    Generates CloudFormation templates from the alarm configuration and output to the out/ directory.
    Then copies the files to the s3 bucket and deploys the cloudformation.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file", required: true
    method_option :bucket, type: :string, desc: "provide custom bucket name, will create a default bucket if not provided"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :stack_name, aliases: :r, type: :string, desc: "set the Cloudformation stack name. Defaults to `guardian`"
    method_option :sns_critical, type: :string, desc: "sns topic arn for the critical alamrs"
    method_option :sns_warning, type: :string, desc: "sns topic arn for the warning alamrs"
    method_option :sns_task, type: :string, desc: "sns topic arn for the task alamrs"
    method_option :sns_informational, type: :string, desc: "sns topic arn for the informational alamrs"

    def deploy
      set_region(options[:region],true)
      s3 = CfnGuardian::S3.new(options[:bucket])
      
      compiler = CfnGuardian::Compile.new(options,s3.bucket)
      compiler.get_resources
      compiler.compile_templates
      logger.info "Clouformation templates compiled successfully in out/ directory"

      s3.create_bucket_if_not_exists
      validator = CfnGuardian::Validate.new(s3.bucket)
      if validator.validate
        logger.error("One or more templates failed to validate")
        exit(1)
      else
        logger.info "Clouformation templates were validated successfully"
      end
      
      deployer = CfnGuardian::Deploy.new(options,s3.bucket)
      deployer.upload_templates
      change_set, change_set_type = deployer.create_change_set()
      deployer.wait_for_changeset(change_set.id)
      deployer.execute_change_set(change_set.id)
      deployer.wait_for_execute(change_set_type)
    end
    
    desc "show-alarms", "Shows alarm settings"
    long_desc <<-LONG
    Displays the configured settings for each alarm. Can be filtered by resource group and alarm name.
    Defaults to show all configured alarms.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file", required: true
    method_option :group, aliases: :g, type: :string, desc: "resource group"
    method_option :name, aliases: :n, type: :string, desc: "alarm name"
    method_option :resource, aliases: :r, type: :string, desc: "resource id"
    def show_alarms
      compiler = CfnGuardian::Compile.new(options,'no-bucket')
      compiler.get_resources
      
      alarms = compiler.resources.select{|h| h[:type] == 'Alarm'}
      groups = alarms.group_by{|h| h[:class]}
      
      if options[:group]
        groups = groups.fetch(options[:group],{}).group_by{|h| h[:class]}
        if options[:resource]
            groups = groups[options[:group]].select{|h| h[:resource] == options[:resource]}.group_by{|h| h[:class]}
        end
        if options[:name]
          groups = groups[options[:group]].select{|h| h[:name] == options[:name]}.group_by{|h| h[:class]}
        end
      end
      
      groups.each do |grp,alarms|
        puts "\n\s\s#{grp}\n"
        alarms.each do |alarm|
          rows = alarm.reject {|k,v| [:type,:class,:name].include?(k)}
                      .sort_by {|k,v| k}
          puts Terminal::Table.new( 
                  :title => alarm[:name], 
                  :headings => ['property', 'Value'], 
                  :rows => rows.map! {|k,v| [k,v.to_s]})
        end
      end
    end
    
    private
    
    def set_region(region,required)
      if !region.nil?
        Aws.config.update({region: region})
      elsif !ENV['AWS_REGION'].nil?
        Aws.config.update({region: ENV['AWS_REGION']})
      elsif !ENV['AWS_DEFAULT_REGION'].nil?
        Aws.config.update({region: ENV['AWS_DEFAULT_REGION']})
      else
        if required
          logger.error("No AWS region found. Please suppy the region using option `--region` or setting environment variables `AWS_REGION` `AWS_DEFAULT_REGION`")
          exit(1)
        end
      end
    end
    
  end
end
