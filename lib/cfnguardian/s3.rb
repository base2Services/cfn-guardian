require 'aws-sdk-s3'

module CfnGuardian
  class S3
    include Logging

    attr_reader :bucket, :path

    def initialize(bucket,path='')
      @bucket = set_bucket_name(bucket)
      @path = path
    end

    def set_bucket_name(bucket)
      if bucket.nil?
        sts = Aws::STS::Client.new
        account_id = sts.get_caller_identity().account
        return "#{account_id}.#{Aws.config[:region]}.guardian.templates"
      end
      return bucket
    end

    def create_bucket_if_not_exists()
      s3 = Aws::S3::Client.new
      begin
        s3.head_bucket(bucket: @bucket)
        logger.info("Found bucket #{@bucket}")
      rescue
        logger.info("Creating bucket #{@bucket}")
        s3.create_bucket(bucket: @bucket)
      end
      return bucket
    end
    
  end
end