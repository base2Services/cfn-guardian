require 'aws-sdk-cloudformation'

module CfnGuardian
  class Drift
    
    def initialize(stack)
      @stack = stack
      @client = Aws::CloudFormation::Client.new()
    end
    
    def find_nested_stacks
      stacks = []
      resp = @client.describe_stack_resources({
        stack_name: @stack
      })
      resp.stack_resources.each do |r|
        if r.resource_type == 'AWS::CloudFormation::Stack'
          stacks << r.physical_resource_id
        end
      end
      return stacks
    end
    
    def detect_drift(stack)
      resp = @client.detect_stack_drift({
        stack_name: stack
      })
      wait_for_dirft_detection(resp.stack_drift_detection_id)
    end
    
    def wait_for_dirft_detection(id,count=0)
      resp = @client.describe_stack_drift_detection_status({
        stack_drift_detection_id: id
      })
      if resp.detection_status == 'DETECTION_IN_PROGRESS' && count < 10
        sleep(2)
        count += 1
        wait_for_dirft_detection(id,count)
      end
    end
    
    def get_drift(stack)
      rows = []
      resp = @client.describe_stack_resource_drifts({
        stack_name: stack,
        stack_resource_drift_status_filters: ["MODIFIED", "DELETED"]
      })
      
      if resp.stack_resource_drifts.any?
        resp.stack_resource_drifts.each do |drift|
          next if drift.resource_type != 'AWS::CloudWatch::Alarm'
          
          if drift.stack_resource_drift_status == 'MODIFIED'
            drift.property_differences.each do |diff|
              rows << [
                drift.physical_resource_id,
                diff.property_path,
                diff.expected_value,
                diff.actual_value,
                diff.difference_type
              ]
            end
          elsif drift.stack_resource_drift_status == 'DELETED'
            rows << [
              drift.physical_resource_id.red,
              "",
              "",
              "",
              drift.stack_resource_drift_status.red
            ]
          end
        end
      end
      
      return rows
    end
    
  end
end