require 'spec_helper'
require 'json'
require 'yaml'
require 'tmpdir'
require 'term/ansicolor'
require 'cfnguardian/log'
require 'cfnguardian/models/alarm'
require 'cfnguardian/stacks/resources'
require 'cfnguardian/resources/base'
require 'cfnguardian/resources/ec2_instance'
require 'cfnguardian/resources/sqs_queue'
require 'cfnguardian/resources/application_targetgroup'
require 'cfnguardian/compile'

RSpec.describe 'Anomaly detection alarm support' do

  describe CfnGuardian::Models::BaseAlarm do
    let(:resource) { { 'Id' => 'test-resource' } }
    let(:alarm) { CfnGuardian::Models::BaseAlarm.new(resource) }

    it 'initializes anomaly_detection to false' do
      expect(alarm.anomaly_detection).to eq(false)
    end

    it 'initializes standard_deviation to nil' do
      expect(alarm.standard_deviation).to be_nil
    end

    it 'initializes threshold_overridden to false' do
      expect(alarm.threshold_overridden).to eq(false)
    end

    it 'allows setting anomaly_detection' do
      alarm.anomaly_detection = true
      expect(alarm.anomaly_detection).to eq(true)
    end

    it 'allows setting standard_deviation' do
      alarm.standard_deviation = 3
      expect(alarm.standard_deviation).to eq(3)
    end

    it 'does not expose a public threshold_overridden= writer' do
      # threshold_overridden must only be settable internally via mark_threshold_overridden!,
      # otherwise a YAML config could set ThresholdOverridden directly through
      # update_object's generic setter dispatch and bypass validation.
      expect(alarm.respond_to?(:threshold_overridden=)).to eq(false)
      expect { alarm.threshold_overridden = true }.to raise_error(NoMethodError)
    end

    it 'marks threshold_overridden via the internal marker method' do
      expect(alarm.threshold_overridden).to eq(false)
      alarm.mark_threshold_overridden!
      expect(alarm.threshold_overridden).to eq(true)
    end

    it 'does not mark threshold_overridden just from calling the plain accessor' do
      # threshold_overridden is only set true by base.rb's update_object (a config
      # override), not by a resource group's own default_alarms definition calling
      # the plain accessor directly - so the accessor alone must not flip it.
      alarm.threshold = 80
      expect(alarm.threshold_overridden).to eq(false)
      expect(alarm.threshold).to eq(80)
    end
  end

  describe CfnGuardian::Resource::Ec2Instance do
    let(:resource) { { 'Id' => 'i-0123456789abcdef0' } }
    let(:resource_class) { CfnGuardian::Resource::Ec2Instance.new(resource) }

    it 'does not mark threshold_overridden from the resource group default_alarms definition' do
      alarms = resource_class.get_alarms('Ec2Instance', {})
      cpu_alarm = alarms.find { |a| a.name == 'CPUUtilizationHigh' }

      # default_alarms() sets alarm.threshold = 90 directly, not through a config
      # override, so it must not trip the AnomalyDetection/Threshold conflict check.
      expect(cpu_alarm.threshold).to eq(90)
      expect(cpu_alarm.threshold_overridden).to eq(false)
    end

    it 'marks threshold_overridden when Threshold is set via a config override' do
      overrides = { 'CPUUtilizationHigh' => { 'Threshold' => 95 } }
      alarms = resource_class.get_alarms('Ec2Instance', overrides)
      cpu_alarm = alarms.find { |a| a.name == 'CPUUtilizationHigh' }

      expect(cpu_alarm.threshold).to eq(95)
      expect(cpu_alarm.threshold_overridden).to eq(true)
    end
  end

  describe CfnGuardian::Models::Ec2InstanceAlarm do
    let(:resource) { { 'Id' => 'i-0123456789abcdef0' } }
    let(:alarm) { CfnGuardian::Models::Ec2InstanceAlarm.new(resource) }

    it 'can be converted to an anomaly detection alarm' do
      alarm.anomaly_detection = true
      alarm.standard_deviation = 3
      alarm.comparison_operator = 'GreaterThanUpperThreshold'
      expect(alarm.anomaly_detection).to eq(true)
      expect(alarm.standard_deviation).to eq(3)
    end
  end

  describe CfnGuardian::Stacks::Resources do
    let(:template) { CfnDsl::CloudFormationTemplate.new }
    let(:stack) { CfnGuardian::Stacks::Resources.new(template) }
    let(:resource) { { 'Id' => 'i-0123456789abcdef0' } }

    context 'with a standard alarm' do
      let(:alarm) do
        a = CfnGuardian::Models::Ec2InstanceAlarm.new(resource)
        a.name = 'CPUUtilizationHigh'
        a.metric_name = 'CPUUtilization'
        a.threshold = 90
        a.evaluation_periods = 10
        a.alarm_action = 'Critical'
        a.maintenance_groups = []
        a
      end

      it 'emits a static Threshold and no Metrics/ThresholdMetricId' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        props = alarm_resource['Properties']

        expect(props['Threshold']).to eq(90)
        expect(props).not_to have_key('Metrics')
        expect(props).not_to have_key('ThresholdMetricId')
      end
    end

    context 'with an anomaly detection alarm' do
      let(:alarm) do
        a = CfnGuardian::Models::Ec2InstanceAlarm.new(resource)
        a.name = 'CPUUtilizationHigh'
        a.metric_name = 'CPUUtilization'
        a.statistic = 'Average'
        a.evaluation_periods = 3
        a.alarm_action = 'Critical'
        a.maintenance_groups = []
        a.anomaly_detection = true
        a.standard_deviation = 2
        a.comparison_operator = 'GreaterThanUpperThreshold'
        a
      end

      it 'emits Metrics and ThresholdMetricId instead of a static Threshold' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        props = alarm_resource['Properties']

        expect(props).to have_key('Metrics')
        expect(props).to have_key('ThresholdMetricId')
        expect(props).not_to have_key('Threshold')
        expect(props).not_to have_key('Dimensions')
        expect(props).not_to have_key('MetricName')
        expect(props).not_to have_key('Namespace')
        expect(props).not_to have_key('Statistic')
      end

      it 'sets up the raw metric and ANOMALY_DETECTION_BAND metric data queries' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        metrics = alarm_resource['Properties']['Metrics']

        expect(metrics.length).to eq(2)

        raw_metric = metrics.find { |m| m['Id'] == 'm1' }
        expect(raw_metric['ReturnData']).to eq(true)
        expect(raw_metric['MetricStat']['Metric']['Namespace']).to eq('AWS/EC2')
        expect(raw_metric['MetricStat']['Metric']['MetricName']).to eq('CPUUtilization')
        expect(raw_metric['MetricStat']['Metric']['Dimensions']).to eq([{ 'Name' => 'InstanceId', 'Value' => 'i-0123456789abcdef0' }])
        expect(raw_metric['MetricStat']['Stat']).to eq('Average')

        band_metric = metrics.find { |m| m['Id'] == 'ad1' }
        expect(band_metric['Expression']).to eq('ANOMALY_DETECTION_BAND(m1, 2)')
        expect(band_metric['ReturnData']).to eq(true)

        expect(alarm_resource['Properties']['ThresholdMetricId']).to eq('ad1')
        expect(alarm_resource['Properties']['ComparisonOperator']).to eq('GreaterThanUpperThreshold')
      end

      it 'defaults the standard deviation band width to 2 when not set' do
        alarm.standard_deviation = nil
        new_template = CfnDsl::CloudFormationTemplate.new
        new_stack = CfnGuardian::Stacks::Resources.new(new_template)
        new_stack.build_template([alarm])
        output = JSON.parse(new_template.to_json)
        alarm_resource = output['Resources'].values.first
        metrics = alarm_resource['Properties']['Metrics']

        band_metric = metrics.find { |m| m['Id'] == 'ad1' }
        expect(band_metric['Expression']).to eq('ANOMALY_DETECTION_BAND(m1, 2)')
      end

      it 'still emits EvaluateLowSampleCountPercentile when set, matching the standard alarm branch' do
        alarm.evaluate_low_sample_count_percentile = 'ignore'
        new_template = CfnDsl::CloudFormationTemplate.new
        new_stack = CfnGuardian::Stacks::Resources.new(new_template)
        new_stack.build_template([alarm])
        output = JSON.parse(new_template.to_json)
        alarm_resource = output['Resources'].values.first

        expect(alarm_resource['Properties']['EvaluateLowSampleCountPercentile']).to eq('ignore')
      end

      it 'omits EvaluateLowSampleCountPercentile when not set' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first

        expect(alarm_resource['Properties']).not_to have_key('EvaluateLowSampleCountPercentile')
      end
    end

    context 'with an anomaly detection alarm whose default statistic is an ExtendedStatistic' do
      let(:tg_resource) { { 'Id' => 'my-target-group', 'LoadBalancer' => 'my-alb' } }
      let(:alarm) do
        a = CfnGuardian::Models::ApplicationTargetGroupAlarm.new(tg_resource)
        a.name = 'TargetResponseTime'
        a.metric_name = 'TargetResponseTime'
        a.extended_statistic = 'p95'
        a.evaluation_periods = 5
        a.alarm_action = 'Critical'
        a.maintenance_groups = []
        a.anomaly_detection = true
        a.standard_deviation = 2
        a.comparison_operator = 'GreaterThanUpperThreshold'
        a
      end

      it 'uses the ExtendedStatistic (not the default Statistic) as the MetricStat.Stat' do
        stack.build_template([alarm])
        output = JSON.parse(template.to_json)
        alarm_resource = output['Resources'].values.first
        metrics = alarm_resource['Properties']['Metrics']

        raw_metric = metrics.find { |m| m['Id'] == 'm1' }
        # alarm.statistic still defaults to 'Maximum' since only extended_statistic was set;
        # the anomaly Metrics must prefer the ExtendedStatistic, matching the non-anomaly path.
        expect(alarm.statistic).to eq('Maximum')
        expect(raw_metric['MetricStat']['Stat']).to eq('p95')
      end
    end
  end

  describe 'Validation' do
    def compile_config(config)
      Dir.mktmpdir do |tmpdir|
        fixture = File.join(tmpdir, 'test_alarms.yaml')
        File.write(fixture, config.to_yaml)
        compile = CfnGuardian::Compile.new(fixture, false)
        compile.get_resources
        compile
      end
    end

    context 'with a valid anomaly detection alarm' do
      it 'does not raise validation errors' do
        result = compile_config({
          'Resources' => {
            'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
          },
          'Templates' => {
            'Ec2Instance' => {
              'CPUUtilizationHigh' => {
                'AnomalyDetection' => true,
                'StandardDeviation' => 2,
                'ComparisonOperator' => 'GreaterThanUpperThreshold'
              },
              'StatusCheckFailed' => false
            }
          }
        })

        anomaly_alarms = result.alarms.select { |a| a.anomaly_detection }
        expect(anomaly_alarms.length).to eq(1)
        expect(anomaly_alarms.first.comparison_operator).to eq('GreaterThanUpperThreshold')
      end
    end

    context 'when anomaly detection alarm also sets a static Threshold' do
      it 'raises a validation error' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold',
                  'Threshold' => 80
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /cannot set both Threshold and AnomalyDetection/)
      end
    end

    context 'when anomaly detection alarm uses an invalid ComparisonOperator' do
      it 'raises a validation error' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanThreshold'
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /invalid ComparisonOperator/)
      end
    end

    context 'when anomaly detection alarm has an invalid StandardDeviation' do
      it 'raises a validation error' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold',
                  'StandardDeviation' => -1
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /invalid StandardDeviation/)
      end
    end

    context 'when anomaly detection alarm has a StandardDeviation of .nan' do
      it 'raises a validation error instead of compiling a NaN into ANOMALY_DETECTION_BAND' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold',
                  'StandardDeviation' => YAML.load('.nan')
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /invalid StandardDeviation/)
      end
    end

    context 'when anomaly detection alarm has a StandardDeviation of .inf' do
      it 'raises a validation error instead of compiling an Infinity into ANOMALY_DETECTION_BAND' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold',
                  'StandardDeviation' => YAML.load('.inf')
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /invalid StandardDeviation/)
      end
    end

    context 'when both SearchExpression and AnomalyDetection are set' do
      it 'raises a validation error' do
        expect {
          compile_config({
            'Resources' => {
              'AutoScalingGroup' => [{ 'Id' => 'my-app-AsgGroup-abc123' }]
            },
            'Templates' => {
              'AutoScalingGroup' => {
                'CPUUtilizationHighBase' => {
                  'SearchExpression' => "SEARCH('{AWS/EC2,AutoScalingGroupName} MetricName=\"CPUUtilization\" my-app', 'Minimum', 60)",
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold'
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /cannot set both SearchExpression and AnomalyDetection/)
      end
    end

    context 'when AnomalyDetection is set to a non-boolean value' do
      it 'raises a validation error instead of silently generating a static alarm' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => 'true',
                  'ComparisonOperator' => 'GreaterThanUpperThreshold'
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /invalid AnomalyDetection value/)
      end
    end

    context 'when a config tries to set ThresholdOverridden directly to bypass the conflict check' do
      it 'still raises the Threshold/AnomalyDetection conflict error' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold',
                  'Threshold' => 80,
                  'ThresholdOverridden' => false
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /cannot set both Threshold and AnomalyDetection/)
      end
    end

    context 'when anomaly detection alarm is missing MetricName/Namespace' do
      it 'raises a validation error' do
        expect {
          compile_config({
            'Resources' => {
              'Batch' => [{ 'Id' => 'my-batch-job' }]
            },
            'Templates' => {
              'Batch' => {
                'CustomAnomalyAlarm' => {
                  'AnomalyDetection' => true,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold'
                }
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /nil value for property/)
      end
    end

    context 'when AnomalyDetection is explicitly false but ComparisonOperator is an anomaly-only operator' do
      it 'raises a validation error instead of falling through to a static-threshold alarm' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'AnomalyDetection' => false,
                  'ComparisonOperator' => 'GreaterThanUpperThreshold'
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /requires AnomalyDetection to be true/)
      end
    end

    context 'when AnomalyDetection is not set (inherits the false default) but ComparisonOperator is an anomaly-only operator' do
      it 'raises a validation error instead of falling through to a static-threshold alarm' do
        expect {
          compile_config({
            'Resources' => {
              'Ec2Instance' => [{ 'Id' => 'i-0123456789abcdef0' }]
            },
            'Templates' => {
              'Ec2Instance' => {
                'CPUUtilizationHigh' => {
                  'ComparisonOperator' => 'LessThanLowerOrGreaterThanUpperThreshold'
                },
                'StatusCheckFailed' => false
              }
            }
          })
        }.to raise_error(CfnGuardian::ValidationError, /requires AnomalyDetection to be true/)
      end
    end
  end
end
