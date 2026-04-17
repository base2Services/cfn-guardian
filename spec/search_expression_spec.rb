require 'spec_helper'
require 'json'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'term/ansicolor'
require 'cfnguardian/log'
require 'cfnguardian/models/alarm'
require 'cfnguardian/stacks/resources'
require 'cfnguardian/resources/base'
require 'cfnguardian/resources/autoscaling_group'
require 'cfnguardian/compile'

RSpec.describe 'Search expression alarm support' do

  describe CfnGuardian::Models::BaseAlarm do
    let(:resource) { { 'Id' => 'test-resource' } }
    let(:alarm) { CfnGuardian::Models::BaseAlarm.new(resource) }

    it 'initializes search_expression to nil' do
      expect(alarm.search_expression).to be_nil
    end

    it 'initializes search_aggregation to nil' do
      expect(alarm.search_aggregation).to be_nil
    end

    it 'allows setting search_expression' do
      alarm.search_expression = "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\"', 'Maximum', 60)"
      expect(alarm.search_expression).to include('SEARCH')
    end

    it 'allows setting search_aggregation' do
      alarm.search_aggregation = 'AVG'
      expect(alarm.search_aggregation).to eq('AVG')
    end
  end

  describe CfnGuardian::Models::AutoScalingGroupAlarm do
    let(:resource) { { 'Id' => 'my-app-AsgGroup-abc123' } }
    let(:alarm) { CfnGuardian::Models::AutoScalingGroupAlarm.new(resource) }

    it 'defaults to standard dimensions with no search expression' do
      expect(alarm.dimensions).to eq({ AutoScalingGroupName: 'my-app-AsgGroup-abc123' })
      expect(alarm.search_expression).to be_nil
    end

    it 'can be converted to a search expression alarm' do
      alarm.search_expression = "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" my-app-AsgGroup', 'Minimum', 60)"
      alarm.search_aggregation = 'MAX'
      expect(alarm.search_expression).to include('my-app-AsgGroup')
      expect(alarm.search_aggregation).to eq('MAX')
    end
  end

  describe CfnGuardian::Stacks::Resources do
    let(:template) { CfnDsl::CloudFormationTemplate.new }
    let(:stack) { CfnGuardian::Stacks::Resources.new(template) }
    let(:resource) { { 'Id' => 'my-asg-abc123' } }

    context 'with a standard alarm' do
      let(:alarm) do
        a = CfnGuardian::Models::AutoScalingGroupAlarm.new(resource)
        a.name = 'CPUUtilizationHighBase'
        a.metric_name = 'CPUUtilization'
        a.statistic = 'Minimum'
        a.threshold = 90
        a.evaluation_periods = 10
        a.alarm_action = 'Critical'
        a.maintenance_groups = []
        a
      end

      it 'emits Dimensions, MetricName, Namespace, and Statistic' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        props = alarm_resource['Properties']

        expect(props).to have_key('Dimensions')
        expect(props).to have_key('MetricName')
        expect(props).to have_key('Namespace')
        expect(props).to have_key('Statistic')
        expect(props).not_to have_key('Metrics')
      end
    end

    context 'with a search expression alarm' do
      let(:alarm) do
        a = CfnGuardian::Models::AutoScalingGroupAlarm.new(resource)
        a.name = 'CPUUtilizationHighBase'
        a.metric_name = 'CPUUtilization'
        a.threshold = 90
        a.evaluation_periods = 10
        a.alarm_action = 'Critical'
        a.maintenance_groups = []
        a.search_expression = "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" my-asg', 'Minimum', 60)"
        a.search_aggregation = 'MAX'
        a
      end

      it 'emits Metrics instead of Dimensions' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        props = alarm_resource['Properties']

        expect(props).to have_key('Metrics')
        expect(props).not_to have_key('Dimensions')
        expect(props).not_to have_key('MetricName')
        expect(props).not_to have_key('Namespace')
        expect(props).not_to have_key('Statistic')
        expect(props).not_to have_key('Period')
      end

      it 'sets up the search and aggregation metric data queries' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        metrics = alarm_resource['Properties']['Metrics']

        expect(metrics.length).to eq(2)

        search_metric = metrics.find { |m| m['Id'] == 'search_expression' }
        expect(search_metric['Expression']).to include('SEARCH')
        expect(search_metric['ReturnData']).to eq(false)

        agg_metric = metrics.find { |m| m['Id'] == 'aggregate' }
        expect(agg_metric['Expression']).to eq('MAX(search_expression)')
        expect(agg_metric['ReturnData']).to eq(true)
      end

      it 'defaults aggregation to MAX when search_aggregation is nil' do
        alarm.search_aggregation = nil
        new_template = CfnDsl::CloudFormationTemplate.new
        new_stack = CfnGuardian::Stacks::Resources.new(new_template)
        new_stack.build_template([alarm])
        output = JSON.parse(new_template.to_json)
        alarm_resource = output['Resources'].values.first
        metrics = alarm_resource['Properties']['Metrics']

        agg_metric = metrics.find { |m| m['Id'] == 'aggregate' }
        expect(agg_metric['Expression']).to eq('MAX(search_expression)')
      end
    end
  end

  describe 'Search expression variable interpolation' do
    let(:resource) { { 'Id' => 'my-app-AsgGroup-abc123', 'Name' => 'my-app' } }
    let(:resource_class) { CfnGuardian::Resource::AutoScalingGroup.new(resource) }

    it 'interpolates ${Resource::Id} in search expressions' do
      overrides = {
        'CPUUtilizationHighBase' => {
          'SearchExpression' => "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" ${Resource::Id}', 'Minimum', 60)",
          'SearchAggregation' => 'MAX'
        }
      }

      alarms = resource_class.get_alarms('AutoScalingGroup', overrides)
      cpu_alarm = alarms.find { |a| a.name == 'CPUUtilizationHighBase' }

      expect(cpu_alarm.search_expression).to include('my-app-AsgGroup-abc123')
      expect(cpu_alarm.search_expression).not_to include('${Resource::Id}')
    end

    it 'interpolates ${Resource::Name} in search expressions' do
      overrides = {
        'CPUUtilizationHighBase' => {
          'SearchExpression' => "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" ${Resource::Name}', 'Minimum', 60)",
          'SearchAggregation' => 'MAX'
        }
      }

      alarms = resource_class.get_alarms('AutoScalingGroup', overrides)
      cpu_alarm = alarms.find { |a| a.name == 'CPUUtilizationHighBase' }

      expect(cpu_alarm.search_expression).to include('my-app')
      expect(cpu_alarm.search_expression).not_to include('${Resource::Name}')
    end
  end

  describe 'Validation' do
    context 'when search expression alarm has no metric_name or namespace' do
      it 'does not raise validation errors' do
        Dir.mktmpdir do |tmpdir|
          fixture = File.join(tmpdir, 'search_expression_alarms.yaml')
          File.write(fixture, {
            'Resources' => {
              'AutoScalingGroup' => [{ 'Id' => 'my-app-AsgGroup-abc123' }]
            },
            'Templates' => {
              'AutoScalingGroup' => {
                'CPUUtilizationHighBase' => {
                  'SearchExpression' => "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" my-app', 'Minimum', 60)",
                  'SearchAggregation' => 'MAX'
                },
                'StatusCheckFailed' => false
              }
            }
          }.to_yaml)

          compile = CfnGuardian::Compile.new(fixture, false)
          compile.get_resources
          search_alarms = compile.alarms.select { |a| a.search_expression }
          expect(search_alarms.length).to eq(1)
          expect(search_alarms.first.search_expression).to include('SEARCH')
        end
      end
    end
  end
end
