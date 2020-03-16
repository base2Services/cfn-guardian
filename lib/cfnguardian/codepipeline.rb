require 'aws-sdk-codepipeline'
require 'time'
require 'cfnguardian/log'

module CfnGuardian
  class CodePipeline
    include Logging
    
    def initialize(pipeline_name)
      @pipeline_name = pipeline_name
      client = Aws::CodePipeline::Client.new()
      @pipeline = client.get_pipeline_state({
        name: @pipeline_name
      })
    end
    
    def retry()
      resp = client.start_pipeline_execution({
        name: @pipeline_name,
        client_request_token: "ClientRequestToken",
      })
    end
    
    def get_stage(stage_name)
      return @pipeline.stage_states.find {|stage| stage.stage_name == stage_name}
    end
    
    def colour_rows(rows, status)
      if status == 'Failed'
        rows.map! {|row| row.map! {|r| r.red } }
      elsif status == 'Succeeded'
        rows.map! {|row| row.map! {|r| r.green } }
      elsif status == 'InProgress'
        rows.map! {|row| row.map! {|r| r.blue } }
      elsif ["Stopped", "Stopping"].include? status
        rows.map! {|row| row.map! {|r| r.yellow } }
      end
    end
    
    def get_source()
      source_stage = get_stage("Source")
      action = source_stage.action_states.first
      status = source_stage.latest_execution.status
      state = {
        stage: action.action_name,
        rows: [
          ['Status', status],
          ['Commit', action.current_revision.revision_id],
          ['Last Status Change', action.latest_execution.last_status_change.localtime.strftime("%d/%m/%Y %I:%M %p")]
        ]
      }
      
      unless action.latest_execution.error_details.nil?
        state[:rows].push(
          ['Error Message', action.latest_execution.error_details.message]
        )
      end
      
      colour_rows(state[:rows],status)
      
      return state
    end
    
    def get_build()
      source_stage = get_stage("Build")
      action = source_stage.action_states.first
      status = source_stage.latest_execution.status
      state = {
        stage: action.action_name,
        rows: [
          ['Status', status],
          ['Build Id', action.latest_execution.external_execution_id],
          ['Last Status Change', action.latest_execution.last_status_change.localtime.strftime("%d/%m/%Y %I:%M %p")],
          ['Logs', action.latest_execution.external_execution_url]
        ]
      }
      
      unless action.latest_execution.error_details.nil?
        state[:rows].push(
          ['Error Message', action.latest_execution.error_details.message]
        )
      end
      
      colour_rows(state[:rows],status)
      
      return state
    end
    
    def get_create_changeset()
      source_stage = get_stage("Deploy")
      action = source_stage.action_states.find {|action| action.action_name == "CreateChangeSet"}
      status = source_stage.latest_execution.status
      state = {
        stage: action.action_name,
        rows: [
          ['Status', status],
          ['Summary', action.latest_execution.summary],
          ['Last Status Change', action.latest_execution.last_status_change.localtime.strftime("%d/%m/%Y %I:%M %p")],
        ]
      }
      
      unless action.latest_execution.error_details.nil?
        state[:rows].push(
          ['Error Message', action.latest_execution.error_details.message]
        )
      end
      
      colour_rows(state[:rows],status)
      
      return state
    end
    
    def get_deploy_changeset()
      source_stage = get_stage("Deploy")
      action = source_stage.action_states.find {|action| action.action_name == "DeployChangeSet"}
      status = source_stage.latest_execution.status
      state = {
        stage: action.action_name,
        rows: [
          ['Status', status],
          ['Summary', action.latest_execution.summary],
          ['Last Status Change', action.latest_execution.last_status_change.localtime.strftime("%d/%m/%Y %I:%M %p")],
        ]
      }
      
      unless action.latest_execution.error_details.nil?
        state[:rows].push(
          ['Error Message', action.latest_execution.error_details.message]
        )
      end
      
      colour_rows(state[:rows],status)
      
      return state
    end
    
  end
end