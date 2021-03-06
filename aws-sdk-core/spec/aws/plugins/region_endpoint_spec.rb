require 'spec_helper'

module Aws
  module Plugins
    describe RegionalEndpoint do

      let(:env) {{}}

      let(:metadata) {{
        'endpointPrefix' => 'PREFIX',
      }}

      let(:client_class) {
        Seahorse::Client::Base.define(
          plugins: [RegionalEndpoint],
          api: Aws::Api::Builder.build('metadata' => metadata)
        )
      }

      before do
        stub_const("ENV", env)
      end

      describe 'region option' do

        it 'adds a :region configuration option' do
          expect(client_class.new(region: 'region').config.region).to eq('region')
        end

        it 'defaults to ENV["AWS_DEFAULT_REGION"]' do
          env['AWS_DEFAULT_REGION'] = 'env-region'
          expect(client_class.new.config.region).to eq('env-region')
        end

        it 'defaults to ENV["AWS_REGION"]' do
          env['AWS_REGION'] = 'env-fallback1'
          expect(client_class.new.config.region).to eq('env-fallback1')
        end

        it 'falls back to ENV["AMAZON_REGION"]' do
          env['AMAZON_REGION'] = 'region-fallback2'
          expect(client_class.new.config.region).to eq('region-fallback2')
        end

        it 'prefers AWS_DEFAULT_REGION to AWS_REGION or AMAZON_REGION' do
          env['AWS_REGION'] = 'aws-region'
          env['AMAZON_REGION'] = 'amazon-region'
          env['AWS_DEFAULT_REGION'] = 'aws-default-region'
          expect(client_class.new.config.region).to eq('aws-region')
        end

        it 'prefers AWS_REGION to AMAZON_REGION' do
          env['AWS_REGION'] = 'aws-region'
          env['AMAZON_REGION'] = 'amazon-region'
          expect(client_class.new.config.region).to eq('aws-region')
        end

        it 'can be set directly, overriding the ENV["AWS_REGION"]' do
          env['AWS_REGION'] = 'env-region'
          expect(client_class.new(region:'cfg').config.region).to eq('cfg')
        end

        it 'raises an argument error when not set' do
          client = Seahorse::Client::Base.define
          client.add_plugin(RegionalEndpoint)
          expect {
            client.new(endpoint:'http://foo.com')
          }.to raise_error(Errors::MissingRegionError)
        end

        it 'raises an argument error when set to nil' do
          client = Seahorse::Client::Base.define
          client.add_plugin(RegionalEndpoint)
          expect {
            client.new(endpoint:'http://foo.com', region: nil)
          }.to raise_error(Errors::MissingRegionError)
        end

      end

      describe 'endpoint option' do

        it 'defaults the endpoint to PREFIX.REGION.amazonaws.com' do
          client = client_class.new(region: 'REGION')
          expect(client.config.endpoint.to_s).to eq('https://PREFIX.REGION.amazonaws.com')
        end

      end
    end
  end
end
