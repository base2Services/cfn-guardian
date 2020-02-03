require 'thor'
require 'terminal-table'
require 'term/ansicolor'
require "cfnguardian/log"
require "cfnguardian/version"
require "cfnguardian/compile"
require "cfnguardian/validate"
require "cfnguardian/deploy"
require "cfnguardian/cloudwatch"
require "cfnguardian/drift"

module CfnGuardian
  class Cli < Thor
    include Logging
    
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
    method_option :region, aliases: :r, type: :string, desc: "set the AWS region"

    def compile
      set_log_level(options[:debug])
      
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
    method_option :stack_name, aliases: :s, type: :string, desc: "set the Cloudformation stack name. Defaults to `guardian`"
    method_option :sns_critical, type: :string, desc: "sns topic arn for the critical alamrs"
    method_option :sns_warning, type: :string, desc: "sns topic arn for the warning alamrs"
    method_option :sns_task, type: :string, desc: "sns topic arn for the task alamrs"
    method_option :sns_informational, type: :string, desc: "sns topic arn for the informational alamrs"

    def deploy
      set_log_level(options[:debug])
      
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
    
    desc "show-drift", "Cloudformation drift detection"
    long_desc <<-LONG
    Displays any cloudformation drift detection in the cloudwatch alarms from the deployed stacks
    LONG
    method_option :stack_name, aliases: :s, type: :string, default: 'guardian', desc: "set the Cloudformation stack name"
    
    def show_drift
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
        exit(1)
      end
    end
    
    desc "show-alarms", "Shows alarm settings"
    long_desc <<-LONG
    Displays the configured settings for each alarm. Can be filtered by resource group and alarm name.
    Defaults to show all configured alarms.
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file", required: true
    method_option :group, aliases: :g, type: :string, desc: "resource group"
    method_option :alarm, aliases: :a, type: :string, desc: "alarm name"
    method_option :id, type: :string, desc: "resource id"
    method_option :compare, type: :boolean, default: false, desc: "compare config to deployed alarms"
    
    def show_alarms
      set_log_level(options[:debug])
      
      compiler = CfnGuardian::Compile.new(options,'no-bucket')
      compiler.get_resources
      alarms = filter_alarms(compiler.alarms,options)

      if alarms.empty?
        logger.error "No matches found" 
        exit 1
      end
      
      if options[:compare]
        CfnGuardian::CloudWatch.compare_alarms(alarms,compiler.topics)
      end
      
      groups = alarms.group_by{|h| h[:class]}
      groups.each do |grp,alarms|        
        alarms.each do |alarm|
          headings = ['Property', 'Config']
          rows = alarm.reject {|k,v| [:type,:class,:name].include?(k)}
                      .sort_by {|k,v| k}
                      
          if options[:compare]
            headings.push('Deployed')
            rows.select! {|k,v| !v.first.nil?}
            rows.map! do |k,v| 
              if v.first.to_s == v.last.to_s || v.last.nil?
                [k.to_s.green,v.first.to_s.green,v.last.to_s.green]
              else
                [k.to_s.red,v.first.to_s.red,v.last.to_s.red]
              end
            end
          else
            rows.select! {|k,v| !v.nil?}.map! {|k,v| [k,v.to_s]}
          end
          
          puts Terminal::Table.new( 
                  :title => "#{grp}::#{alarm[:name]}".green, 
                  :headings => headings, 
                  :rows => rows)
        end
      end
    end
    
    desc "show-state", "Shows alarm state in cloudwatch"
    long_desc <<-LONG
    Displays the current cloudwatch alarm state
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file"
    method_option :group, aliases: :g, type: :string, desc: "resource group"
    method_option :alarm, aliases: :a, type: :string, desc: "alarm name"
    method_option :id, type: :string, desc: "resource id"
    method_option :state, aliases: :s, type: :string, enum: %w(OK ALARM INSUFFICIENT_DATA), desc: "filter by alarm state"
    method_option :alarm_names, type: :array, desc: "CloudWatch alarm name if not providing config"
    method_option :alarm_prefix, type: :string, desc: "CloudWatch alarm name prefix if not providing config"
    
    def show_state
      set_log_level(options[:debug])
      
      if !options[:config].nil?
        compiler = CfnGuardian::Compile.new(options,'no-bucket')
        compiler.get_resources
        alarms = filter_alarms(compiler.alarms,options)
        alarms.map! {|alarm| "#{alarm[:class]}-#{alarm[:resource]}-#{alarm[:name]}"}
        rows = CfnGuardian::CloudWatch.get_alarm_state(alarm_names: alarms, state: options[:state])
      elsif !options[:alarm_names].nil?
        rows = CfnGuardian::CloudWatch.get_alarm_state(alarm_names: options[:alarm_names], state: options[:state])
      elsif !options[:alarm_prefix].nil?
        rows = CfnGuardian::CloudWatch.get_alarm_state(alarm_prefix: options[:alarm_prefix], state: options[:state])
      else
        logger.error "one of `--config` `--alarm-prefix` `--alarm-names` must be supplied"
        exit 1
      end
      
            
      puts Terminal::Table.new( 
              :title => "Alarm State", 
              :headings => ['Alarm Name', 'State', 'Changed'], 
              :rows => rows)
    end
    
    desc "show-history", "Shows alarm history for the last 7 days"
    long_desc <<-LONG
    Displays the alarm state or config history for the last 7 days
    LONG
    method_option :config, aliases: :c, type: :string, desc: "yaml config file"
    method_option :group, aliases: :g, type: :string, desc: "resource group"
    method_option :alarm, aliases: :a, type: :string, desc: "alarm name"
    method_option :alarm_names, type: :array, desc: "CloudWatch alarm name if not providing config"
    method_option :id, type: :string, desc: "resource id"
    method_option :type, aliases: :t, type: :string, 
        enum: %w(state config), default: 'state', desc: "filter by alarm state"
    
    def show_history
      set_log_level(options[:debug])
      
      if !options[:config].nil?
        compiler = CfnGuardian::Compile.new(options,'no-bucket')
        compiler.get_resources
        alarms = filter_alarms(compiler.alarms,options)
        alarms.map! {|alarm| "#{alarm[:class]}-#{alarm[:resource]}-#{alarm[:name]}"}
      elsif !options[:alarm_names].nil?
        alarms = options[:alarm_names]
      else
        logger.error "one of `--config` `--alarm-names` must be supplied"
        exit 1
      end
        
      
      case options[:type]
      when 'state'
        type = 'StateUpdate'
        headings = ['Date', 'Summary', 'Reason']
      when 'config'
        type = 'ConfigurationUpdate'
        headings = ['Date', 'Summary', 'Type']
      end
      
      alarms.each do |alarm|
        rows = CfnGuardian::CloudWatch.get_alarm_history(alarm,type)
        if rows.any?     
          puts Terminal::Table.new( 
                  :title => alarm, 
                  :headings => headings, 
                  :rows => rows)
          puts "\n"
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
    
    def set_log_level(debug)
      logger.level = debug ? Logger::DEBUG : Logger::INFO
    end
    
    def filter_alarms(alarms,options)
      alarms.select! {|alarm| alarm[:class].downcase == options[:group].downcase} if options[:group]
      alarms.select! {|alarm| alarm[:resource].downcase == options[:id].downcase} if options[:id]
      alarms.select! {|alarm| alarm[:name].downcase.include? options[:alarm].downcase} if options[:alarm]
      return alarms
    end
    
  end
end
