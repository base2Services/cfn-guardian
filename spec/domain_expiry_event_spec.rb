require 'spec_helper'
require 'json'
require 'digest'
require 'term/ansicolor'
require 'cfnguardian/string'
require 'cfnguardian/models/event'

RSpec.describe CfnGuardian::Models::DomainExpiryEvent do
  describe '#payload' do
    it 'includes the region so the check publishes its metric' do
      event = described_class.new('Id' => 'example.com')

      payload = JSON.parse(event.payload)

      expect(payload).to eq('Domain' => 'example.com', 'Region' => '${AWS::Region}')
    end

    it 'uses the configured region when one is set' do
      event = described_class.new('Id' => 'example.com', 'Region' => 'us-east-1')

      expect(JSON.parse(event.payload)['Region']).to eq('us-east-1')
    end
  end
end
