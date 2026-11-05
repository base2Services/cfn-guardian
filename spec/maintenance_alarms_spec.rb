require 'spec_helper'
require 'cfnguardian'

RSpec.describe CfnGuardian::Cli do
  before do
    allow(Aws.config).to receive(:update)
  end

  %w[disable enable].each do |verb|
    describe "#{verb}-alarms" do
      it 'acts only on the alarm names passed with --alarms' do
        expect(CfnGuardian::CloudWatch).not_to receive(:get_alarm_names)
        expect(CfnGuardian::CloudWatch).to receive(:"#{verb}_alarms").with(['alarm-1', 'alarm-2'])

        described_class.start(["#{verb}-alarms", '--region', 'us-east-1', '--alarms', 'alarm-1', 'alarm-2'])
      end

      it 'looks up alarms by --alarm-prefix' do
        expect(CfnGuardian::CloudWatch).to receive(:get_alarm_names).with(nil, 'guardian-ECSService').and_return(['guardian-ECSService-app-UnhealthyTaskCritical'])
        expect(CfnGuardian::CloudWatch).to receive(:"#{verb}_alarms").with(['guardian-ECSService-app-UnhealthyTaskCritical'])

        described_class.start(["#{verb}-alarms", '--region', 'us-east-1', '--alarm-prefix', 'guardian-ECSService'])
      end

      it 'looks up alarms by --group' do
        expect(CfnGuardian::CloudWatch).to receive(:get_alarm_names).with('AppUpdate', nil).and_return(['guardian-alarm'])
        expect(CfnGuardian::CloudWatch).to receive(:"#{verb}_alarms").with(['guardian-alarm'])

        described_class.start(["#{verb}-alarms", '--region', 'us-east-1', '--group', 'AppUpdate'])
      end

      it 'refuses to run without --alarms, --group or --alarm-prefix' do
        expect(CfnGuardian::CloudWatch).not_to receive(:get_alarm_names)
        expect(CfnGuardian::CloudWatch).not_to receive(:"#{verb}_alarms")

        expect {
          expect {
            described_class.start(["#{verb}-alarms", '--region', 'us-east-1'])
          }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        }.to output(/one of `--alarms`, `--group` or `--alarm-prefix` must be supplied/).to_stderr
      end
    end
  end
end
