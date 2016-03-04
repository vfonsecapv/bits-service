require 'spec_helper'
require 'securerandom'

module BitsService
  module Routes
    describe Droplets do
      let(:headers) { Hash.new }

      let(:zip_filename) { 'file.zip' }

      let(:zip_filepath) do
        path = File.join(Dir.mktmpdir, zip_filename)
        TestZip.create(path, 1, 1024)
        path
      end

      let(:zip_file) do
        Rack::Test::UploadedFile.new(File.new(zip_filepath))
      end

      let(:zip_file_sha) { Digester.new.digest_path(zip_file) }

      let(:non_zip_file) do
        Rack::Test::UploadedFile.new(Tempfile.new('foo'))
      end

      let(:guid) { SecureRandom.uuid }

      let(:upload_body) { { droplet: zip_file, droplet_name: zip_filename } }

      let(:use_nginx) { false }

      let(:config) do
        {
          droplets: {
            fog_connection: {
              provider: 'AWS',
              aws_access_key_id: 'fake_aws_key_id',
              aws_secret_access_key: 'fake_secret_access_key'
            }
          },
          nginx: {
            use_nginx: use_nginx
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

      after(:each) do
        FileUtils.rm_rf(File.dirname(zip_filepath))
        FileUtils.rm_f(non_zip_file.tempfile.path)
      end

      describe 'POST /droplets' do
        before do
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
          allow(SecureRandom).to receive(:uuid).and_return(guid)
        end

        it 'returns HTTP status 201' do
          post '/droplets', upload_body, headers
          expect(last_response.status).to eq(201)
        end

        it 'stores the uploaded file in the droplet blobstore using the correct key' do
          blobstore = double(BitsService::Blobstore::Client)
          expect_any_instance_of(Routes::Droplets).to receive(:droplet_blobstore).and_return(blobstore)
          expect(blobstore).to receive(:cp_to_blobstore).with(zip_filepath, guid)

          post '/droplets', upload_body, headers
        end

        it 'returns json with metadata about the upload' do
          post '/droplets', upload_body, headers

          json = MultiJson.load(last_response.body)
          expect(json['guid']).to eq(guid)
          expect(json['digest']).to be
          expect(json['digest']).to eq(zip_file_sha)
        end

        it 'instantiates the upload params decorator with the right arguments' do
          expect(Helpers::Upload::Params).to receive(:new).with(hash_including('droplet' => anything), use_nginx: false).once
          post '/droplets', upload_body, headers
        end

        it 'gets the uploaded filepath from the upload params decorator' do
          decorator = double(Helpers::Upload::Params)
          allow(Helpers::Upload::Params).to receive(:new).and_return(decorator)
          expect(decorator).to receive(:upload_filepath).with('droplet').once
          post '/droplets', upload_body, headers
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
          post '/droplets', upload_body, headers
          expect(File.exist?(zip_filepath)).to be_falsy
        end

        context 'when an empty file is being uploaded' do
          let(:zip_filepath) do
            path = File.join(Dir.mktmpdir, zip_filename)
            TestZip.create(path, 1, 0)
            path
          end

          it 'returns json with metadata about the upload' do
            post '/droplets', upload_body, headers

            json = MultiJson.load(last_response.body)
            expect(json['guid']).to eq(guid)
            expect(json['digest']).to be
            expect(json['digest']).to eq(zip_file_sha)
          end
        end

        context 'when no file is being uploaded' do
          before(:each) do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(nil)
          end

          it 'returns a corresponding error' do
            expect_any_instance_of(Routes::Droplets).to_not receive(:droplet_blobstore)

            post '/droplets', upload_body, headers

            expect(last_response.status).to eq(400)
            json = MultiJson.load(last_response.body)
            expect(json['code']).to eq(290_003)
            expect(json['description']).to match(/a file must be provided/)
          end
        end

        context 'when the blobstore copy fails' do
          before(:each) do
            allow_any_instance_of(Blobstore::Client).to receive(:cp_to_blobstore).and_raise('some error')
          end

          it 'return HTTP status 500' do
            post '/droplets', upload_body, headers
            expect(last_response.status).to eq(500)
          end

          it 'does not leave the temporary instance of the uploaded file around' do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
            post '/droplets', upload_body, headers
            expect(File.exist?(zip_filepath)).to be_falsy
          end
        end

        context 'when the blobstore helper fails' do
          before(:each) do
            allow_any_instance_of(Routes::Droplets).to receive(:droplet_blobstore).and_raise('some error')
          end

          it 'return HTTP status 500' do
            post '/droplets', upload_body, headers
            expect(last_response.status).to eq(500)
          end

          it 'does not leave the temporary instance of the uploaded file around' do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
            allow_any_instance_of(Helpers::Upload::Params).to receive(:original_filename).and_return(zip_filename)
            post '/droplets', upload_body, headers
            expect(File.exist?(zip_filepath)).to be_falsy
          end
        end
      end

      describe 'GET /droplets/:guid' do
        let(:download_url) { 'some-url' }

        let(:blob) do
          double(BitsService::Blobstore::Blob, download_url: download_url)
        end

        let(:blobstore) do
          double(BitsService::Blobstore::Client).tap do |blobstore|
            allow(blobstore).to receive(:blob).with(guid).and_return(blob)
          end
        end

        before(:each) do
          allow_any_instance_of(Routes::Droplets).to receive(:droplet_blobstore).and_return(blobstore)
        end

        it 'creates the droplet blobstore using the blobstore factory' do
          expect_any_instance_of(Routes::Droplets).to receive(:droplet_blobstore).at_least(:once)
          get "/droplets/#{guid}", headers
        end

        it 'finds the blob inside the blobstore using the correct guid' do
          expect(blobstore).to receive(:blob).with(guid)
          get "/droplets/#{guid}", headers
        end

        it 'checks whether the blobstore is local' do
          expect(blobstore).to receive(:local?).once
          get "/droplets/#{guid}", headers
        end

        context 'when the blobstore is local' do
          before(:each) do
            allow(blobstore).to receive(:local?).and_return(true)
          end

          context 'and we are using nginx' do
            let(:use_nginx) { true }

            it 'returns HTTP status code 200' do
              get "/droplets/#{guid}", headers
              expect(last_response.status).to eq(200)
            end

            it 'sets the X-Accel-Redirect response header' do
              get "/droplets/#{guid}", headers
              expect(last_response.headers).to include('X-Accel-Redirect' => download_url)
            end

            it 'gets the download_url from the blob' do
              expect(blob).to receive(:download_url).once
              get "/droplets/#{guid}", headers
            end
          end

          context 'and we are not using nginx' do
            let(:use_nginx) { false }

            before(:each) do
              allow(blob).to receive(:local_path).and_return(zip_filepath)
            end

            it 'returns HTTP status code 200' do
              get "/droplets/#{guid}", headers
              expect(last_response.status).to eq(200)
            end

            it 'sets the right Content-Type header' do
              get "/droplets/#{guid}", headers
              expect(last_response.headers).to include('Content-Type' => 'application/zip')
            end

            it 'sets the right Content-Length header' do
              get "/droplets/#{guid}", headers
              expect(last_response.headers).to include('Content-Length' => File.size(zip_filepath).to_s)
            end

            it 'returns the file contents in the response body' do
              get "/droplets/#{guid}", headers
              expect(last_response.body).to eq(File.open(zip_filepath, 'rb').read)
            end

            it 'does not set the X-Accel-Redirect response header' do
              get "/droplets/#{guid}", headers
              expect(last_response.headers).to_not include('X-Accel-Redirect')
            end

            it 'gets the local_path from the blob' do
              expect(blob).to receive(:local_path).once
              get "/droplets/#{guid}", headers
            end
          end
        end

        context 'when the blobstore is remote' do
          before(:each) do
            allow(blobstore).to receive(:local?).and_return(false)
          end

          it 'returns HTTP status code 302' do
            get "/droplets/#{guid}", headers
            expect(last_response.status).to eq(302)
          end

          it 'sets the location header to the correct value' do
            get "/droplets/#{guid}", headers
            expect(last_response.headers).to include('Location' => download_url)
          end
        end

        context 'when the droplet does not exist' do
          let(:blob) { nil }

          it 'returns a corresponding error' do
            get "/droplets/#{guid}", headers

            expect(last_response.status).to eq(404)
            json = MultiJson.load(last_response.body)
            expect(json['code']).to eq(10_000)
            expect(json['description']).to match(/Unknown request/)
          end
        end
      end

      describe 'DELETE /droplets/:guid' do
        let(:blob) do
          double(BitsService::Blobstore::Blob)
        end

        let(:blobstore) do
          double(BitsService::Blobstore::Client, blob: blob)
        end

        before(:each) do
          allow_any_instance_of(Routes::Droplets).to receive(:droplet_blobstore).and_return(blobstore)
          allow(blobstore).to receive(:delete_blob).and_return(true)
        end

        it 'returns HTTP status code 204' do
          delete "/droplets/#{guid}", headers
          expect(last_response.status).to eq(204)
        end

        it 'deletes the blob using the blobstore client' do
          expect(blobstore).to receive(:delete_blob).with(blob)
          delete "/droplets/#{guid}", headers
        end

        context 'when the buildpack does not exist' do
          let(:blob) { nil }

          it 'returns a corresponding error' do
            delete "/droplets/#{guid}", headers

            expect(last_response.status).to eq(404)
            json = MultiJson.load(last_response.body)
            expect(json['code']).to eq(10_000)
            expect(json['description']).to match(/Unknown request/)
          end
        end
      end
    end
  end
end
