require 'spec_helper'

module BitsService
  module Routes
    describe 'logger' do
      let(:headers) { Hash.new }

      let(:config) do
        {
          buildpacks: {
            fog_connection: {
              provider: 'AWS',
              aws_access_key_id: 'fake_aws_key_id',
              aws_secret_access_key: 'fake_secret_access_key'
            }
          },
          nginx: {
            use_nginx: 'false'
          }
        }
      end

      around(:each) do |example|
        config_filepath = create_config_file(config)
        BitsService::Environment.load_configuration(config_filepath)
        Fog.mock!

        example.run

        Fog.unmock!
        FileUtils.rm_f(config_filepath)
      end

      it 'creates a log entry' do
        expect_any_instance_of(Steno::Logger).to receive(:info).at_least(:twice)
        get '/buildpacks/1234-5678-90', headers
      end

      it 'creates an entry on request start and end' do
        result = {}

        expect_any_instance_of(Steno::Logger).to receive(:info).at_least(:twice) do |logger, event, hash|
          result[event] = hash
        end

        get '/buildpacks/1234-5678-90', headers

        expect(result['request.started']).to be
        expect(result['request.started']).to include(:path)
        expect(result['request.started'][:path]).to eq('/buildpacks/1234-5678-90')

        expect(result['request.started']).to include(:method)
        expect(result['request.started'][:method]).to eq('GET')

        expect(result['request.ended']).to be
        expect(result['request.ended']).to include(:response_code)
        expect(result['request.ended'][:response_code]).to eq(404)
      end

      context 'when the vcap_request_id is present'
      let(:vcap_request_id) { '4711-XYZ' }
      let(:headers) { { 'HTTP_X_VCAP_REQUEST_ID' => vcap_request_id } }

      it 'includes the vcap_request_id' do
        result = {}

        expect_any_instance_of(Steno::Logger).to receive(:info).at_least(:twice) do |logger, event, hash|
          result[event] = hash
        end

        get '/buildpacks/1234-5678-90', {}, headers

        expect(result['request.started']).to be
        expect(result['request.started']).to include(:vcap_request_id)
        expect(result['request.started'][:vcap_request_id]).to eq(vcap_request_id)

        expect(result['request.ended']).to be
        expect(result['request.ended']).to include(:vcap_request_id)
        expect(result['request.ended'][:vcap_request_id]).to eq(vcap_request_id)
      end
    end

    context 'when the vcap_request_id is present' do
      let(:vcap_request_id) { nil }
      let(:headers) { {} }

      it 'includes an empty vcap_request_id' do
        result = {}

        expect_any_instance_of(Steno::Logger).to receive(:info).at_least(:twice) do |logger, event, hash|
          result[event] = hash
        end

        get '/buildpacks/1234-5678-90', {}, headers

        expect(result['request.started']).to be
        expect(result['request.started']).to include(:vcap_request_id)
        expect(result['request.started'][:vcap_request_id]).to_not be

        expect(result['request.ended']).to be
        expect(result['request.ended']).to include(:vcap_request_id)
        expect(result['request.ended'][:vcap_request_id]).to_not be
      end
    end
  end
end
