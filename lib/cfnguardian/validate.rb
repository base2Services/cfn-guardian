require 'aws-sdk-cloudformation'
require 'fileutils'
require 'cfnguardian/version'
require 'cfnguardian/log'
require 'cfnguardian/s3'

module CfnGuardian
  class Validate
    include Logging

    def initialize(bucket)
      @bucket = bucket
      @prefix = "validation"
      @client = Aws::CloudFormation::Client.new()
    end

    def validate()
      success = []
      Dir["out/*.yaml"].each do |template|
        file_size_bytes = File.size(template)

        if file_size_bytes > 51200
          success << validate_s3(template)
        else
          success << validate_local(template)
        end
      end
      return success.include?(false)
    end
    
    def validate_local(path)
      logger.info "Validating template #{path} locally"
      template = File.read path
      begin
        response = @client.validate_template({
          template_body: template
        })
      rescue Aws::CloudFormation::Errors::ValidationError => e
        logger.warn("template #{path} failed validation with error:\n====> #{e.message}")
        return false
      end
      return true
    end

    def validate_s3(path)
      success = true
      logger.info "Validating template #{path} from s3 bucket #{@bucket}"
      
      template = File.read path
      md5 = Digest::MD5.hexdigest template
      prefix = "#{@prefix}/#{md5}"

      client = Aws::S3::Client.new()
      client.put_object({
        body: template,
        bucket: @bucket,
        key: prefix
      })
      logger.info("uploaded #{path} to s3://#{@bucket}/#{prefix}")
      
      begin
        response = @client.validate_template({
          template_url: "https://#{@bucket}.s3.amazonaws.com/#{prefix}"
        })
      rescue Aws::CloudFormation::Errors::ValidationError => e
        logger.warn("template #{path} failed validation with error:\n====> #{e.message}")
        success = false
      end

      client.put_object({
        bucket: @bucket,
        key: prefix
      })
      logger.debug("deleted s3://#{@bucket}/#{prefix}")
      
      return success
    end

  end
end
