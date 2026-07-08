require 'spec_helper'
require 'json'
require 'digest'
require 'term/ansicolor'
require 'cfnguardian/string'
require 'cfnguardian/models/event'

RSpec.describe CfnGuardian::Models::HttpEvent do
  describe '#payload' do
    it 'includes health config overrides in headers for HMAC signing' do
      event = described_class.new(
        'Id' => 'https://api.example.com/health',
        'HmacSecretSsm' => '/guardian/myapp/hmac-secret',
        'HealthConfigOverrides' => {
          'roles' => {
            'my_service' => {
              'probes' => [{ 'id' => 'my-probe', 'enabled' => false }]
            }
          }
        }
      )

      payload = JSON.parse(event.payload)

      expect(payload['HMAC_SECRET_SSM']).to eq('/guardian/myapp/hmac-secret')
      expect(payload['HEADERS']).to eq(
        'X-Health-Config-Overrides={"roles":{"my_service":{"probes":[{"id":"my-probe","enabled":false}]}}}'
      )
    end

    it 'merges explicit headers with health config overrides' do
      event = described_class.new(
        'Id' => 'https://api.example.com/health',
        'Headers' => 'content-type=application/json',
        'HealthConfigOverrides' => '{"enabled":true}'
      )

      payload = JSON.parse(event.payload)

      expect(payload['HEADERS']).to eq(
        'content-type=application/json X-Health-Config-Overrides={"enabled":true}'
      )
    end
  end
end
