require 'spec_helper'
require 'tempfile'
require 'yaml'
require 'cfnguardian'

RSpec.describe CfnGuardian::Compile do
  def compile(config)
    file = Tempfile.new(['alarms', '.yaml'])
    file.write(config.to_yaml)
    file.close
    compiler = described_class.new(file.path, false)
    compiler.get_resources
    compiler
  ensure
    file.unlink
  end

  describe '#get_resources' do
    it 'compiles known resource groups' do
      compiler = compile('Resources' => { 'StepFunctions' => [{ 'Id' => 'my-machine' }] })

      expect(compiler.alarms.map(&:group).uniq).to eq(['StepFunctions'])
    end

    it 'still compiles a group defined through a template Inherit' do
      compiler = compile(
        'Templates' => { 'MyQueues' => { 'Inherit' => 'SQSQueue' } },
        'Resources' => { 'MyQueues' => [{ 'Id' => 'my-queue' }] }
      )

      expect(compiler.alarms).not_to be_empty
    end

    it 'fails on an unknown resource group and suggests the case-insensitive match' do
      expect {
        compile('Resources' => { 'Stepfunctions' => [{ 'Id' => 'my-machine' }] })
      }.to raise_error(CfnGuardian::ValidationError, /'Stepfunctions' is not a valid resource group\. Did you mean 'StepFunctions'\?/)
    end

    it 'fails on an unknown resource group without a suggestion when nothing is close' do
      expect {
        compile('Resources' => { 'Bogus' => [{ 'Id' => 'x' }] })
      }.to raise_error(CfnGuardian::ValidationError) { |error|
        expect(error.message).to include("'Bogus' is not a valid resource group.")
        expect(error.message).not_to include('Did you mean')
      }
    end

    it 'reports every unknown group once, even when other groups are valid' do
      config = {
        'Resources' => {
          'Stepfunctions' => [{ 'Id' => 'one' }, { 'Id' => 'two' }],
          'Bogus' => [{ 'Id' => 'x' }],
          'SQSQueue' => [{ 'Id' => 'my-queue' }]
        }
      }

      expect { compile(config) }.to raise_error(CfnGuardian::ValidationError) { |error|
        expect(error.message).to start_with('2 errors found')
        expect(error.message.scan("'Stepfunctions' is not a valid resource group").size).to eq(1)
        expect(error.message).to include("'Bogus' is not a valid resource group")
      }
    end
  end
end
