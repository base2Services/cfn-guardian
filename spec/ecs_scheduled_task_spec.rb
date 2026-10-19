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

    context 'when a cluster has several entries' do
      let(:templates) { { 'MemoryUtilizedHigh' => { 'MetricName' => 'MemoryUtilized', 'Threshold' => 1800 } } }

      def alarm_for(resource)
        described_class.new(resource).get_alarms('ECSScheduledTask', templates).first
      end

      it 'keeps the name and hash of a cluster-wide alarm unchanged' do
        alarm = alarm_for({ 'Id' => 'cluster' })
        expect(alarm.resource_hash).to eq(Digest::MD5.hexdigest('cluster'))
        expect(CfnGuardian::CloudWatch.get_alarm_name(alarm)).to eq('guardian-ECSScheduledTask-cluster-MemoryUtilizedHigh')
      end

      it 'includes the family in the name of a family alarm' do
        alarm = alarm_for({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'a' })
        expect(CfnGuardian::CloudWatch.get_alarm_name(alarm)).to eq('guardian-ECSScheduledTask-cluster-a-MemoryUtilizedHigh')
      end

      it 'does not collide between a cluster-wide and a family entry' do
        wide = alarm_for({ 'Id' => 'cluster' })
        family = alarm_for({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'a' })
        expect(wide.resource_hash).not_to eq(family.resource_hash)
        expect(CfnGuardian::CloudWatch.get_alarm_name(wide)).not_to eq(CfnGuardian::CloudWatch.get_alarm_name(family))
      end

      it 'does not collide between two families' do
        a = alarm_for({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'a' })
        b = alarm_for({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'b' })
        expect(a.resource_hash).not_to eq(b.resource_hash)
        expect(CfnGuardian::CloudWatch.get_alarm_name(a)).not_to eq(CfnGuardian::CloudWatch.get_alarm_name(b))
      end

      it 'uses an explicit Name for the alarm name' do
        alarm = alarm_for({ 'Id' => 'cluster', 'TaskDefinitionFamily' => 'a', 'Name' => 'nightly' })
        expect(CfnGuardian::CloudWatch.get_alarm_name(alarm)).to eq('guardian-ECSScheduledTask-nightly-MemoryUtilizedHigh')
      end
    end
  end

  describe 'compiled template' do
    it 'renders an alarm for both a cluster-wide and a family entry on the same cluster' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          File.write('alarms.yaml', {
            'Resources' => { 'ECSScheduledTask' => [
              { 'Id' => 'example-cluster' },
              { 'Id' => 'example-cluster', 'TaskDefinitionFamily' => 'example-a' },
              { 'Id' => 'example-cluster', 'TaskDefinitionFamily' => 'example-b' }
            ] },
            'Templates' => { 'ECSScheduledTask' => { 'MemoryUtilizedHigh' => { 'MetricName' => 'MemoryUtilized', 'Threshold' => 1800 } } }
          }.to_yaml)
          compile = CfnGuardian::Compile.new('alarms.yaml', false)
          compile.get_resources
          compile.compile_templates('guardian.compiled.yaml')

          resources = YAML.load_file('out/guardian.compiled.yaml')['Resources']
          alarms = resources.select { |_, v| v['Type'] == 'AWS::CloudWatch::Alarm' }
          names = alarms.values.map { |v| v['Properties']['AlarmName'] }
          expect(names).to contain_exactly(
            'guardian-ECSScheduledTask-example-cluster-MemoryUtilizedHigh',
            'guardian-ECSScheduledTask-example-cluster-example-a-MemoryUtilizedHigh',
            'guardian-ECSScheduledTask-example-cluster-example-b-MemoryUtilizedHigh'
          )
          expect(alarms.keys).to include("#{Digest::MD5.hexdigest('example-cluster')}ECSScheduledTaskMemoryUtilizedHighAlarm")
        end
      end
    end

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
