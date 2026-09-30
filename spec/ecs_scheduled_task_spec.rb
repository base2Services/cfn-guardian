require 'spec_helper'
require 'json'
require 'yaml'
require 'tmpdir'
require 'term/ansicolor'
require 'cfnguardian/log'
require 'cfnguardian/compile'

RSpec.describe CfnGuardian::Resource::ECSScheduledTask do
  let(:cluster_arn) { 'arn:aws:ecs:${AWS::Region}:${AWS::AccountId}:cluster/batch-jobs' }

  def subscriptions(resource, overrides = {})
    described_class.new(resource).get_event_subscriptions('ECSScheduledTask', overrides)
  end

  let(:standalone) { [{ 'anything-but' => { 'prefix' => 'service:' } }] }

  describe '#get_event_subscriptions' do
    it 'creates TaskFailed and TaskFailedToStart subscriptions by default' do
      subs = subscriptions({ 'Id' => 'batch-jobs' })
      expect(subs.map(&:name)).to contain_exactly('TaskFailed', 'TaskFailedToStart')
      expect(subs.map(&:source).uniq).to eq(['aws.ecs'])
      expect(subs.map(&:detail_type).uniq).to eq(['ECS Task State Change'])
      expect(subs.map(&:topic).uniq).to eq(['Events'])
    end

    it 'matches stopped standalone tasks in the cluster with a non-zero container exit code' do
      failed = subscriptions({ 'Id' => 'batch-jobs' }).find { |s| s.name == 'TaskFailed' }
      expect(failed.detail).to eq({
        'lastStatus' => ['STOPPED'],
        'containers' => { 'exitCode' => [{ 'anything-but' => 0 }] },
        'clusterArn' => [cluster_arn],
        'group' => standalone
      })
    end

    it 'matches standalone tasks that failed to start in the cluster' do
      failed = subscriptions({ 'Id' => 'batch-jobs' }).find { |s| s.name == 'TaskFailedToStart' }
      expect(failed.detail).to eq({
        'lastStatus' => ['STOPPED'],
        'stopCode' => ['TaskFailedToStart'],
        'clusterArn' => [cluster_arn],
        'group' => standalone
      })
    end

    it 'narrows to a task definition family on the task definition ARN' do
      subs = subscriptions({ 'Id' => 'batch-jobs', 'TaskDefinitionFamily' => 'report-export' })
      subs.each do |s|
        expect(s.detail['taskDefinitionArn']).to eq([{ 'prefix' => 'arn:aws:ecs:${AWS::Region}:${AWS::AccountId}:task-definition/report-export:' }])
        expect(s.detail['group']).to eq(standalone)
      end
    end

    it 'gives each family on the same cluster a unique rule' do
      a = subscriptions({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'a' }).first
      b = subscriptions({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'b' }).first
      expect(a.hash).not_to eq(b.hash)
    end

    it 'does not collide when cluster and family names shift characters' do
      a = subscriptions({ 'Id' => 'a', 'TaskDefinitionFamily' => 'bc' }).first
      b = subscriptions({ 'Id' => 'ab', 'TaskDefinitionFamily' => 'c' }).first
      expect(a.hash).not_to eq(b.hash)
    end

    it 'supports disabling and re-routing the default subscriptions' do
      subs = subscriptions({ 'Id' => 'batch-jobs' }, {
        'TaskFailedToStart' => false,
        'TaskFailed' => { 'Topic' => 'Critical' }
      })
      expect(subs.map(&:name)).to eq(['TaskFailed'])
      expect(subs.first.topic).to eq('Critical')
    end

    it 'scopes custom subscriptions to the cluster and family' do
      subs = subscriptions({ 'Id' => 'batch-jobs', 'TaskDefinitionFamily' => 'report-export' }, {
        'SpotInterrupted' => { 'Detail' => { 'stopCode' => ['SpotInterruption'] } }
      })
      spot = subs.find { |s| s.name == 'SpotInterrupted' }
      expect(spot.detail_type).to eq('ECS Task State Change')
      expect(spot.detail['stopCode']).to eq(['SpotInterruption'])
      expect(spot.detail['clusterArn']).to eq([cluster_arn])
      expect(spot.detail['group']).to eq(standalone)
      expect(spot.detail['taskDefinitionArn']).not_to be_nil
    end

    it 'keeps the scope when an inherited subscription overrides Detail' do
      subs = subscriptions({ 'Id' => 'batch-jobs' }, {
        'TaskOutOfMemory' => { 'Inherit' => 'TaskFailed', 'Detail' => { 'containers' => { 'exitCode' => [137] } } }
      })
      oom = subs.find { |s| s.name == 'TaskOutOfMemory' }
      expect(oom.detail['containers']).to eq({ 'exitCode' => [137] })
      expect(oom.detail['clusterArn']).to eq([cluster_arn])
      expect(oom.detail['group']).to eq(standalone)
    end
  end

  describe '#get_alarms' do
    it 'has no default alarms' do
      expect(described_class.new({ 'Id' => 'cluster' }).get_alarms('ECSScheduledTask', {})).to be_empty
    end

    it 'creates Container Insights alarms from templates' do
      alarms = described_class.new({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'report-export' })
        .get_alarms('ECSScheduledTask', { 'MemoryUtilizedHigh' => { 'MetricName' => 'MemoryUtilized', 'Threshold' => 1800 } })
      expect(alarms.length).to eq(1)
      alarm = alarms.first
      expect(alarm.namespace).to eq('ECS/ContainerInsights')
      expect(alarm.dimensions).to eq({ ClusterName: 'cluster', TaskDefinitionFamily: 'report-export' })
      expect(alarm.treat_missing_data).to eq('notBreaching')
      expect(alarm.threshold).to eq(1800)
    end
  end

  describe 'compiled template' do
    it 'renders EventBridge rules targeting the Events topic' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          File.write('alarms.yaml', {
            'Resources' => { 'ECSScheduledTask' => [{ 'Id' => 'batch-jobs' }] }
          }.to_yaml)
          compile = CfnGuardian::Compile.new('alarms.yaml', false)
          compile.get_resources
          compile.compile_templates('guardian.compiled.yaml')

          resources = YAML.load_file('out/guardian.compiled.yaml')['Resources']
          rules = resources.select { |_, v| v['Type'] == 'AWS::Events::Rule' }
            .map { |k, v| [k[/\AECSScheduledTaskEventSubscription(TaskFailed(?:ToStart)?)[0-9a-f]{32}\z/, 1], v] }
            .reject { |name, _| name.nil? }.to_h
          expect(rules.keys).to contain_exactly('TaskFailed', 'TaskFailedToStart')

          rule = rules['TaskFailed']
          pattern = JSON.parse(rule['Properties']['EventPattern']['Fn::Sub'])
          expect(pattern['source']).to eq(['aws.ecs'])
          expect(pattern['detail-type']).to eq(['ECS Task State Change'])
          expect(pattern['detail']['containers']).to eq({ 'exitCode' => [{ 'anything-but' => 0 }] })
          expect(pattern['detail']['group']).to eq([{ 'anything-but' => { 'prefix' => 'service:' } }])
          expect(rule['Properties']['Targets'].first['Arn']).to eq({ 'Ref' => 'Events' })
        end
      end
    end
  end
end
