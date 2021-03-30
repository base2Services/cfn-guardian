require 'aws-sdk-codecommit'
require 'time'
require 'cfnguardian/log'

module CfnGuardian
  class CodeCommit
    include Logging
  
    def initialize(repo_name)
      @repo_name = repo_name
      @client = Aws::CodeCommit::Client.new()
    end
    
    def get_last_commit(branch='master')
      resp = @client.get_branch({
        repository_name: @repo_name,
        branch_name: branch,
      })
      return resp.branch.commit_id
    end
    
    def get_commit_history(branch,count)
      history = []

      begin
        commit = get_last_commit(branch)
      rescue Aws::CodeCommit::Errors::BranchDoesNotExistException => e
        logger.error "Branch #{branch} does not exist in the #{@repo_name} repository"
        return []
      rescue Aws::CodeCommit::Errors::RepositoryDoesNotExistException => e
        logger.error "Respository #{@repo_name} does not exist in this AWS account or region"
        return []
      end
      
      count.times do
        
        resp = @client.get_commit({
          repository_name: @repo_name,
          commit_id: commit
        })
        
        time = Time.strptime(resp.commit.committer.date,'%s')
        
        history << {
          message: resp.commit.message,
          author: resp.commit.author.name,
          date: time.localtime.strftime("%d/%m/%Y %I:%M %p"),
          id: resp.commit.commit_id
        }
        
        if resp.commit.parents.any?
          commit = resp.commit.parents.first
        else
          break
        end
        
      end
      
      return history
    end
    
  end
end