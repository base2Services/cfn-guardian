require 'aws-sdk-cloudwatch'
require 'cfnguardian/cloudwatch'
require 'cfnguardian/log'

module CfnGuardian
  class Tagger
    include Logging

    def initialize()
      @client = Aws::CloudWatch::Client.new(max_attempts: 5)
    end

    def tag_alarm(alarm, global_tags={})
      alarm_arn = CfnGuardian::CloudWatch.get_alarm_arn(alarm)
      
      new_tags = get_tags(alarm, global_tags)
      current_tags = get_alarm_tags(alarm_arn)
      tags_to_delete = get_tags_to_delete(current_tags, new_tags)

      if tags_to_delete.any?
        logger.debug "Removing tags #{tags_to_delete} from alarm #{alarm_arn}"
        @client.untag_resource({
          resource_arn: alarm_arn,
          tag_keys: tags_to_delete
        })
      end

      if tags_changed?(current_tags, new_tags)
        logger.debug "Updating tags on alarm #{alarm_arn}"
        new_tags.delete_if {|key, value| value.include?('?')}
        begin
          alarm_severity = new_tags["guardian:alarm:severity"]
          if alarm_severity.is_a?(Array)
            new_tags["guardian:alarm:severity"] = new_tags["guardian:alarm:severity"].join("/")
          end
            @client.tag_resource({
            resource_arn: alarm_arn,
            tags: new_tags.map {|key,value| {key: key, value: value}}
          })
        rescue Aws::CloudWatch::Errors::InvalidParameterValue => e
          logger.debug "Failed due to invalid character in tags for: #{alarm_arn}"
        end
      end
    end

    def get_tags(alarm, global_tags)
      defaults = {
        'guardian:resource:id' => alarm.resource_id,
        'guardian:resource:group' => alarm.group,
        'guardian:alarm:name' => alarm.name,
        'guardian:alarm:metric' => alarm.metric_name,
        'guardian:alarm:severity' => alarm.alarm_action
      }
      tags = global_tags.merge(defaults)
      return alarm.tags.merge(tags)
    end

    def get_alarm_tags(alarm_arn)
      resp = @client.list_tags_for_resource({
        resource_arn: alarm_arn
      })
      return resp.tags
    end

    def get_tags_to_delete(current_tags, new_tags)
      return current_tags.select {|tag| !new_tags.has_key?(tag.key)}.map {|tag| tag.key}
    end

    def tags_changed?(current_tags, new_tags)
      return tags_to_hash(current_tags) != new_tags
    end

    def tags_to_hash(tags)
      return tags.map {|tag| {tag.key => tag.value} }.reduce(Hash.new, :merge)
    end

  end
end