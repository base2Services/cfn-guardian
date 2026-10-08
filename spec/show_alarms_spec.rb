require 'spec_helper'
require 'tempfile'
require 'cfnguardian'

RSpec.describe CfnGuardian::Cli do
  describe 'show-alarms' do
    def with_config(yaml)
      file = Tempfile.new(['alarms', '.yaml'])
      file.write(yaml)
      file.close
      yield file.path
    ensure
      file.unlink
    end

    it 'displays the configured alarms without needing an AWS account' do
      config = <<~YAML
        Resources:
          StepFunctions:
          - Id: my-machine
      YAML

      with_config(config) do |path|
        expect {
          described_class.start(['show-alarms', '--config', path])
        }.to output(/guardian-StepFunctions-my-machine-ExecutionsFailed/).to_stdout
      end
    end

    it 'applies --filter to the configured alarms' do
      config = <<~YAML
        Resources:
          StepFunctions:
          - Id: my-machine
      YAML

      with_config(config) do |path|
        expect {
          described_class.start(['show-alarms', '--config', path, '--filter', 'alarm:TimedOut'])
        }.to output(/ExecutionsTimedOut/).to_stdout
      end
    end
  end
end
