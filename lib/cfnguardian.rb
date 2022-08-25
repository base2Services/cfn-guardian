require 'thor'
require 'terminal-table'
require 'term/ansicolor'
require "cfnguardian/log"
require "cfnguardian/version"
require "cfnguardian/compile"
require "cfnguardian/validate"
require "cfnguardian/deploy"
require "cfnguardian/cloudwatch"
require "cfnguardian/display_formatter"
require "cfnguardian/drift"
require "cfnguardian/codecommit"
require "cfnguardian/codepipeline"
require "cfnguardian/tagger"

module CfnGuardian
  class Cli < Thor
    include Logging

    def self.exit_on_failure?
      true
    end
    
    map %w[--version -v] => :__print_version
    desc "--version, -v", "print the version"
    def __print_version
      puts CfnGuardian::VERSION
    end
    
    class_option :debug, type: :boolean, default: false, desc: "enable debug logging"
    
    desc "compile", "Generate monitoring CloudFormation templates"
    long_desc <<-LONG
    Generates CloudFormation templates from the alarm configuration and output to the out/ directory.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file", required: true
    method_option :validate, type: :boolean, default: true, desc: "validate cfn templates"
    method_option :bucket, type: :string, desc: "provide custom bucket name, will create a default bucket if not provided"
    method_option :path, type: :string, default: "guardian", desc: "S3 path location for nested stacks"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :template_config, type: :boolean, default: false, desc: "Genrates an AWS CodePipeline cloudformation template configuration file to override parameters"
    method_option :sns_critical, type: :string, desc: "sns topic arn for the critical alarms"
    method_option :sns_warning, type: :string, desc: "sns topic arn for the warning alarms"
    method_option :sns_task, type: :string, desc: "sns topic arn for the task alarms"
    method_option :sns_informational, type: :string, desc: "sns topic arn for the informational alarms"
    method_option :sns_events, type: :string, desc: "sns topic arn for the informational alarms"
    method_option :template_file, type: :string, default: 'guardian.compiled.yaml', desc: "name of the compiled cloudformation template file"

    def compile
      set_log_level(options[:debug])
      
      set_region(options[:region],options[:validate])
      s3 = CfnGuardian::S3.new(options[:bucket],options[:path])

      clean_out_directory()

      compiler = CfnGuardian::Compile.new(options[:config])
      compiler.get_resources
      compiler.compile_templates(options[:template_file])
      logger.info "Cloudformation templates compiled successfully in out/ directory"
      if options[:validate]
        s3.create_bucket_if_not_exists()
        validator = CfnGuardian::Validate.new(s3.bucket)
        validator.validate
      end

      logger.warn "AWS cloudwatch alarms defined in the templates will cost roughly $#{'%.2f' % compiler.cost} per month"

      if options[:template_config]
        logger.info "Generating a AWS CodePipeline template configuration file template-config.guardian.json"
        parameters = compiler.load_parameters(options)
        compiler.genrate_template_config(parameters)
      end
    end

    desc "deploy", "Generates and deploys monitoring CloudFormation templates"
    long_desc <<-LONG
    Generates CloudFormation templates from the alarm configuration and output to the out/ directory.
    Then copies the files to the s3 bucket and deploys the cloudformation.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file", required: true
    method_option :bucket, type: :string, desc: "provide custom bucket name, will create a default bucket if not provided"
    method_option :path, type: :string, default: "guardian", desc: "S3 path location for nested stacks"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :stack_name, aliases: :s, type: :string, default: 'guardian', desc: "set the Cloudformation stack name. Defaults to `guardian`"
    method_option :sns_critical, type: :string, desc: "sns topic arn for the critical alarms"
    method_option :sns_warning, type: :string, desc: "sns topic arn for the warning alarms"
    method_option :sns_task, type: :string, desc: "sns topic arn for the task alarms"
    method_option :sns_informational, type: :string, desc: "sns topic arn for the informational alarms"
    method_option :sns_events, type: :string, desc: "sns topic arn for the informational alarms"
    method_option :tags, type: :hash, desc: "additional tags on the cloudformation stack"
    method_option :tag_yaml, type: :string, desc: "additional tags on the cloudformation stack in a yaml file"
    method_option :role_arn, type: :string, desc: "IAM role arn that CloudFormation assumes when executing the change set"
    method_option :template_file, type: :string, default: 'guardian.compiled.yaml', desc: "name of the compiled cloudformation template file"
    method_option :ignore_empty_change_set, type: :boolean, default: false, desc: "ignore a cloudformation changeset if it contains no changes"

    def deploy
      set_log_level(options[:debug])
      
      set_region(options[:region],true)
      s3 = CfnGuardian::S3.new(options[:bucket],options[:path])
      
      clean_out_directory()

      compiler = CfnGuardian::Compile.new(options[:config])
      compiler.get_resources
      compiler.compile_templates(options[:template_file])
      parameters = compiler.load_parameters(options)
      logger.info "Cloudformation templates compiled successfully in out/ directory"

      s3.create_bucket_if_not_exists
      validator = CfnGuardian::Validate.new(s3.bucket)
      validator.validate
      
      deployer = CfnGuardian::Deploy.new(options,s3.bucket,parameters,options[:template_file],options[:stack_name])
      deployer.upload_templates
      change_set, change_set_type = deployer.create_change_set()
      deployer.wait_for_changeset(change_set.id)
      deployer.execute_change_set(change_set.id)
      deployer.wait_for_execute(change_set_type)
    end

    desc "bulk-deploy", "Generates and deploys multiple monitoring CloudFormation templates from multiple config yamls"
    long_desc <<-LONG
    For each alarm configuration yamll file provided guardian will generate a CloudFormation template in output to the out/ directory.
    The templates are copied to the s3 bucket and the cloudformation stacks are deployed.
    The names of the Cloudformation stacks are determined by the config yaml name. e.g. alarms.myenv.yaml will deploy the stack myenv-guardian
    LONG
    method_option :config, aliases: :c, type: :array, desc: "yaml config files", required: true
    method_option :bucket, type: :string, desc: "provide custom bucket name, will create a default bucket if not provided"
    method_option :path, type: :string, default: "guardian", desc: "S3 path location for nested stacks"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :sns_critical, type: :string, desc: "sns topic arn for the critical alarms"
    method_option :sns_warning, type: :string, desc: "sns topic arn for the warning alarms"
    method_option :sns_task, type: :string, desc: "sns topic arn for the task alarms"
    method_option :sns_informational, type: :string, desc: "sns topic arn for the informational alarms"
    method_option :sns_events, type: :string, desc: "sns topic arn for the informational alarms"
    method_option :tags, type: :hash, desc: "additional tags on the cloudformation stack"
    method_option :tag_yaml, type: :string, desc: "additional tags on the cloudformation stack in a yaml file"
    method_option :role_arn, type: :string, desc: "IAM role arn that CloudFormation assumes when executing the change set"
    method_option :ignore_empty_change_set, type: :boolean, default: false, desc: "ignore a cloudformation changeset if it contains no changes"

    def bulk_deploy
      set_log_level(options[:debug])
      
      set_region(options[:region],true)
      s3 = CfnGuardian::S3.new(options[:bucket],options[:path])
      s3.create_bucket_if_not_exists
      
      clean_out_directory()

      template_file_suffix = 'compiled.yaml'

      compiled = []

      options[:config].each do |config|
        config_basename = File.basename(config, ".yaml")
        template_file_prefix = config_basename == 'alarms' ? "guardian" : config_basename.gsub("alarms.", "")
        template_file = "#{template_file_prefix}.#{template_file_suffix}"

        compiler = CfnGuardian::Compile.new(config)
        compiler.get_resources
        compiler.compile_templates(template_file)
        logger.info "compiled template to out/#{template_file} from yaml config #{config}"
        parameters = compiler.load_parameters(options)

        compiled << {template_file: template_file, parameters: parameters}
        logger.debug("template file #{template_file} generated with parameters: #{parameters}")
      end

      validator = CfnGuardian::Validate.new(s3.bucket)
      validator.validate

      changesets = []

      compiled.each do |stack|
        stack_name = stack[:template_file].gsub('.compiled.yaml', '')
        deployer = CfnGuardian::Deploy.new(options,s3.bucket,stack[:parameters],stack[:template_file],stack_name)
        deployer.upload_templates
        logger.info("creating changeset for stack #{stack_name}")
        change_set, change_set_type = deployer.create_change_set()
        changesets << {deployer: deployer, id: change_set.id, type: change_set_type}
      end

      changesets_executed = []
      changesets.each do |changeset|
        begin 
          changeset[:deployer].wait_for_changeset(changeset[:id])
        rescue CfnGuardian::EmptyChangeSetError => e
          if options[:ignore_empty_change_set]
            Logger.info e.message
            next
          else
            raise
          end
        end
        logger.info("executing changeset #{changeset[:id]}")
        changeset[:deployer].execute_change_set(changeset[:id])
        changesets_executed << changeset
      end

      changesets_executed.each do |changeset|
        logger.info("waiting for changeset #{changeset[:id]} to complete")
        changeset[:deployer].wait_for_execute(changeset[:type])
      end
    end

    desc "tag-alarms", "apply tags to the cloudwatch alarms deployed"
    long_desc <<-LONG
    Because Cloudformation desn't support tagging cloudwatch alarms this command
    applies tags to each cloudwatch alarm created by guardian.
    Guardian defines default tags and this can be added to through the alarms.yaml config.
    LONG
    method_option :config, aliases: :c, type: :array, desc: "yaml config files", required: true
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :tags, type: :hash, desc: "additional tags on the cloudformation stack"
    method_option :tag_yaml, type: :string, desc: "additional tags on the cloudformation stack in a yaml file"

    def tag_alarms
      set_log_level(options[:debug])
      set_region(options[:region],true)

      tags = {}
      if opts.has_key?("tag_yaml")
        tags.merge!(YAML.load_file(opts[:tag_yaml]))
      end
      tags.merge!(opts.fetch(:tags, {}))

      options[:config].each do |config|
        logger.info "tagging alarms from config file #{config}"
        compiler = CfnGuardian::Compile.new(config)
        compiler.get_resources
        alarms = compiler.alarms
        global_tags = compiler.global_tags.merge(tags)

        tagger = CfnGuardian::Tagger.new()
        alarms.each {|alarm| tagger.tag_alarm(alarm, global_tags) }
      end
    end

    desc "show-drift", "Cloudformation drift detection"
    long_desc <<-LONG
    Displays any cloudformation drift detection in the cloudwatch alarms from the deployed stacks
    LONG
    method_option :stack_name, aliases: :s, type: :string, default: 'guardian', desc: "set the Cloudformation stack name"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"

    def show_drift
      set_region(options[:region],true)
      
      rows = []
      drift = CfnGuardian::Drift.new(options[:stack_name])
      nested_stacks = drift.find_nested_stacks
      nested_stacks.each do |stack|
        drift.detect_drift(stack)
        rows << drift.get_drift(stack)
      end
      
      if rows.any?
        puts Terminal::Table.new( 
                :title => "Guardian Alarm Drift".green, 
                :headings => ['Alarm Name', 'Property', 'Expected', 'Actual', 'Type'], 
                :rows => rows.flatten(1))
      end
    end
    
    desc "show-alarms", "Shows alarm settings"
    long_desc <<-LONG
    Displays the configured settings for each alarm. Can be filtered by resource group and alarm name.
    Defaults to show all configured alarms.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file"
    method_option :defaults, type: :boolean, desc: "display default alarms and properties"
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :filter, type: :hash, default: {}, desc: "filter the displayed alarms by [group, resource-id, alarm, stack-id, topic, maintenance-group]"
    method_option :compare, type: :boolean, default: false, desc: "compare config to deployed alarms"
    
    def show_alarms
      set_log_level(options[:debug])
      set_region(options[:region],options[:compare])
      
      if options[:config]
        config_file = options[:config]
      elsif options[:defaults]
        config_file = default_config()
      else
        raise Thor::Error, 'one of `--config YAML` or `--defaults` must be supplied'
      end
      
      compiler = CfnGuardian::Compile.new(config_file)
      compiler.get_resources
      alarms = filter_compiled_alarms(compiler.alarms,options[:filter])

      if alarms.empty?
        raise Thor::Error, "No matches found" 
      end
      
      headings = ['Property', 'Config']
      formatter = CfnGuardian::DisplayFormatter.new(alarms)
      
      if options[:compare] && !options[:defaults]
        metric_alarms = CfnGuardian::CloudWatch.get_alarms_by_prefix(prefix: 'guardian')
        metric_alarms = CfnGuardian::CloudWatch.filter_alarms(filters: options[:filter], alarms: metric_alarms)

        formatted_alarms = formatter.compare_alarms(metric_alarms)
        headings.push('Deployed')
      else
        formatted_alarms = formatter.alarms()
      end

      if formatted_alarms.any?
        formatted_alarms.each do |fa|
          puts Terminal::Table.new( 
                  :title => fa[:title], 
                  :headings => headings, 
                  :rows => fa[:rows])
        end
      else
        if options[:compare] && !options[:defaults]
          logger.info "No difference found between you config and alarms in deployed AWS"
        else
          logger.warn "No alarms found"
        end
      end
    end
    
    desc "show-state", "Shows alarm state in cloudwatch"
    long_desc <<-LONG
    Displays the current cloudwatch alarm state. By default it will return all the guardian alarms.
    LONG
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :state, aliases: :s, type: :string, enum: %w(OK ALARM INSUFFICIENT_DATA), desc: "filter by alarm state"
    method_option :alarm_names, type: :array, desc: "list of cloudwatch alarm names"
    method_option :alarm_prefix, type: :string, default: "guardian", desc: "cloudwatch alarm name prefix"
    method_option :filter, type: :hash, default: {}, desc: "filter the displayed alarms by [group, resource-id, alarm, stack-id, topic, maintenance-group]"

    def show_state
      set_log_level(options[:debug])
      set_region(options[:region],true)
      action_prefix = nil

      if options[:filter].has_key?('topic')
        action_prefix = get_topic_arn_from_stack(options[:filter]['topic'])
      elsif options[:filter].has_key?('maintenance-group')
        action_prefix = "arn:aws:sns:#{Aws.config[:region]}:#{CfnGuardian::CloudWatch.aws_account_id()}:#{options[:filter]['maintenance-group']}MaintenanceGroup"
      end

      if options[:alarm_names]
        metric_alarms = CfnGuardian::CloudWatch.get_alarms_by_name(alarm_names: options[:alarm_names], state: options[:state], action_prefix: action_prefix)
      else
        metric_alarms = CfnGuardian::CloudWatch.get_alarms_by_prefix(prefix: options[:alarm_prefix], state: options[:state], action_prefix: action_prefix)
      end

      metric_alarms = CfnGuardian::CloudWatch.filter_alarms(filters: options[:filter], alarms: metric_alarms)

      formatter = CfnGuardian::DisplayFormatter.new()
      rows = formatter.alarm_state(metric_alarms)
      
      if rows.any?
        puts Terminal::Table.new( 
              :title => "Alarm State", 
              :headings => ['Alarm Name', 'State', 'Changed', 'Notifications'], 
              :rows => rows)
      else
        logger.warn "No alarms found"
      end
    end
    
    desc "show-history", "Shows alarm history for the last 7 days"
    long_desc <<-LONG
    Displays the alarm state or config history for the last 7 days
    LONG
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :alarm_names, type: :array, desc: "list of cloudwatch alarm names"
    method_option :type, aliases: :t, type: :string, 
        enum: %w(state config), default: 'state', desc: "filter by alarm state"
    method_option :alarm_prefix, type: :string, default: "guardian", desc: "cloudwatch alarm name prefix"
    method_option :filter, type: :hash, desc: "filter the displayed alarms by [group, resource-id, alarm, stack-id]"
    
    def show_history
      set_log_level(options[:debug])
      set_region(options[:region],true)
      
      if options[:alarm_names]
        metric_alarms = CfnGuardian::CloudWatch.get_alarms_by_name(alarm_names: options[:alarm_names], state: options[:state])
      else
        metric_alarms = CfnGuardian::CloudWatch.get_alarms_by_prefix(prefix: options[:alarm_prefix], state: options[:state])
      end

      metric_alarms = CfnGuardian::CloudWatch.filter_alarms(filters: options[:filter], alarms: metric_alarms)       
      
      case options[:type]
      when 'state'
        type = 'StateUpdate'
        headings = ['Date', 'Summary', 'Reason']
      when 'config'
        type = 'ConfigurationUpdate'
        headings = ['Date', 'Summary', 'Type']
      end
      
      formatter = CfnGuardian::DisplayFormatter.new()
      
      metric_alarms.each do |alarm|
        history = CfnGuardian::CloudWatch.get_alarm_history(alarm.alarm_name,type)
        rows = formatter.alarm_history(history,type)
        if rows.any?     
          puts Terminal::Table.new( 
                  :title => alarm.alarm_name.green, 
                  :headings => headings, 
                  :rows => rows)
          puts "\n"
        end
      end
    end
    
    desc "show-config-history", "Shows the last 10 commits made to the codecommit repo"
    long_desc <<-LONG
    Shows the last 10 commits made to the codecommit repo
    LONG
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :repository, type: :string, default: 'guardian', desc: "codecommit repository name"
    method_option :branch, type: :string, default: 'master', desc: "codecommit branch"
    method_option :count, type: :numeric, default: 10, desc: "number of last commits to retrieve"
    
    def show_config_history
      set_region(options[:region],true)
    
      history = CfnGuardian::CodeCommit.new(options[:repository]).get_commit_history(options[:branch], options[:count])
      if history.any?
        puts Terminal::Table.new(
          :headings => history.first.keys.map{|h| h.to_s.to_heading}, 
          :rows => history.map(&:values))
      end
    end
    
    desc "show-pipeline", "Shows the current state of the AWS code pipeline"
    long_desc <<-LONG
    Shows the current state of the AWS code pipeline
    LONG
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :pipeline, aliases: :p, type: :string, default: 'guardian', desc: "codepipeline name"
    
    def show_pipeline
      set_region(options[:region],true)
      pipeline = CfnGuardian::CodePipeline.new(options[:pipeline])
      source = pipeline.get_source()
      build = pipeline.get_build()
      create = pipeline.get_create_changeset()
      deploy = pipeline.get_deploy_changeset()

      puts Terminal::Table.new(
        :title => "Stage: #{source[:stage]}",
        :rows => source[:rows])
        
      puts "\t|"
      puts "\t|"
      
      puts Terminal::Table.new(
        :title => "Stage: #{build[:stage]}",
        :rows => build[:rows])
        
      puts "\t|"
      puts "\t|"
      
      puts Terminal::Table.new(
        :title => "Stage: #{create[:stage]}",
        :rows => create[:rows])
        
      puts "\t|"
      puts "\t|"
      
      puts Terminal::Table.new(
        :title => "Stage: #{deploy[:stage]}",
        :rows => deploy[:rows])
    end
    
    desc "disable-alarms", "Disable cloudwatch alarm notifications"
    long_desc <<-LONG
    Disable cloudwatch alarm notifications for a maintenance group or for specific alarms.
    LONG
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :group, aliases: :g, type: :string, desc: "name of the maintenance group defined in the config"
    method_option :alarm_prefix, type: :string, desc: "cloud watch alarm name prefix"
    method_option :alarms, type: :array, desc: "List of cloudwatch alarm names"
    
    def disable_alarms
      set_region(options[:region],true)
      
      alarm_names = CfnGuardian::CloudWatch.get_alarm_names(options[:group],options[:alarm_prefix])
      CfnGuardian::CloudWatch.disable_alarms(alarm_names)
      
      logger.info "Disabled #{alarm_names.length} alarms"
    end
    
    desc "enable-alarms", "Enable cloudwatch alarm notifications"
    long_desc <<-LONG
    Enable cloudwatch alarm notifications for a maintenance group or for specific alarms.
    Once alarms are enable the state is set back to OK to re send notifications of any failed alarms.
    LONG
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"
    method_option :group, aliases: :g, type: :string, desc: "name of the maintenance group defined in the config"
    method_option :alarm_prefix, type: :string, desc: "cloud watch alarm name prefix"
    method_option :alarms, type: :array, desc: "List of cloudwatch alarm names"
    
    def enable_alarms
      set_region(options[:region],true)
      
      alarm_names = CfnGuardian::CloudWatch.get_alarm_names(options[:group],options[:alarm_prefix])
      CfnGuardian::CloudWatch.enable_alarms(alarm_names)
      
      logger.info "#{alarm_names.length} alarms enabled"
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
          raise Thor::Error "No AWS region found. Please suppy the region using option `--region` or setting environment variables `AWS_REGION` `AWS_DEFAULT_REGION`"
        end
      end
    end
    
    def set_log_level(debug)
      logger.level = debug ? Logger::DEBUG : Logger::INFO
    end
    
    def filter_compiled_alarms(alarms,filters)
      filters = filters.slice('group', 'resource', 'alarm', 'topic', 'maintenance-group')
      alarms.select! {|alarm| alarm.group.downcase == filters['group'].downcase} if filters.has_key?('group')
      alarms.select! {|alarm| alarm.resource_id.downcase == filters['resource'].downcase} if filters.has_key?('resource')
      alarms.select! {|alarm| alarm.name.downcase.include? filters['alarm'].downcase} if filters.has_key?('alarm')
      alarms.select! {|alarm| alarm.alarm_action.include? filters['topic']} if filters.has_key?('topic')
      alarms.select! {|alarm| alarm.maintenance_groups.include? "#{filters['maintenance-group']}MaintenanceGroup"} if filters.has_key?('maintenance-group')
      return alarms
    end
    
    def default_config()
      return "#{File.expand_path(File.dirname(__FILE__))}/cfnguardian/config/defaults.yaml"
    end

    def get_topic_arn_from_stack(topic)
      client = Aws::CloudFormation::Client.new()
      resp = client.describe_stacks({ stack_name: @stack_name })
      stack = resp.stacks.first
      parameter = stack.parameters.find {|p| p.parameter_key == topic}
      return !parameter.nil? ? parameter.parameter_value : nil
    end
    
    def clean_out_directory
      Dir["out/*.yaml"].each {|file| File.delete(file)}
    end

  end
end
