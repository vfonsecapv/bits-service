require 'spec_helper'
require 'securerandom'

module Bits
  describe Routes::Buildpacks do

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

    let(:non_zip_file) do
      Rack::Test::UploadedFile.new(Tempfile.new('foo'))
    end

    let(:zip_file_sha) { Digester.new.digest_path(zip_file) }

    let(:buildpack_guid) { SecureRandom.uuid }

    let(:upload_body) { { buildpack: zip_file, buildpack_name: zip_filename  } }

    let(:use_nginx) { false }

    let(:config) do
      {
        buildpacks: {
          fog_connection: {
            provider: 'AWS',
            aws_access_key_id: 'fake_aws_key_id',
            aws_secret_access_key: 'fake_secret_access_key',
          },
        },
        nginx: {
          use_nginx: use_nginx,
        },
      }
    end

    around(:each) do |example|
      config_filepath = create_config_file(config)
      Bits::Environment.load_configuration(config_filepath)
      Fog.mock!

      example.run

      Fog.unmock!
      FileUtils.rm_f(config_filepath)
    end

    after(:each) do
      FileUtils.rm_rf(File.dirname(zip_filepath))
      FileUtils.rm_f(non_zip_file.tempfile.path)
    end

    describe 'PUT /buildpacks/:guid' do
      it 'returns HTTP status 201' do
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
        expect(last_response.status).to eq(201)
      end

      it 'stores the uploaded file in the buildpack blobstore using the correct key' do
        allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
        allow_any_instance_of(UploadParams).to receive(:original_filename).and_return(zip_filename)

        blobstore = double(Bits::Blobstore::Client)
        expect_any_instance_of(Bits::BlobstoreFactory).to receive(:create_buildpack_blobstore).and_return(blobstore)

        expected_key = "#{buildpack_guid}_#{zip_file_sha}"
        expect(blobstore).to receive(:cp_to_blobstore).with(zip_filepath, expected_key)

        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'instantiates the blobstore factory with the right config' do
        expect(Bits::BlobstoreFactory).to receive(:new).with(hash_including(:buildpacks)).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'uses the blobstore factory to create a buildpack blobstore' do
        blobstore_factory = double(Bits::BlobstoreFactory)
        allow(Bits::BlobstoreFactory).to receive(:new).and_return(blobstore_factory)
        expect(blobstore_factory).to receive(:create_buildpack_blobstore).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'instantiates the upload params decorator with the right arguments' do
        expect(UploadParams).to receive(:new).with(hash_including(
          'buildpack' => anything,
          'buildpack_name' => zip_filename,
        ), use_nginx: false).once

        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'gets the uploaded filepath from the upload params decorator' do
        decorator = double(UploadParams)
        allow(UploadParams).to receive(:new).and_return(decorator)
        expect(decorator).to receive(:upload_filepath).with('buildpack').once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'uses the default digester' do
        expect(Digester).to receive(:new).with(no_args).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'gets the sha of the uploaded file from the digester' do
        allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
        expect_any_instance_of(Digester).to receive(:digest_path).with(zip_filepath).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'does not leave the temporary instance of the uploaded file around' do
        allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
        expect(File.exist?(zip_filepath)).to be_falsy
      end

      context 'when the original filename is nil' do
        before(:each) do
          allow_any_instance_of(UploadParams).to receive(:original_filename).and_return(nil)
        end

        it 'returns a corresponding error' do
          expect(Bits::BlobstoreFactory).to_not receive(:new)

          put "/buildpacks/#{buildpack_guid}", upload_body, headers

          expect(last_response.status).to eq(400)
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(290002)
          expect(json['description']).to match(/a filename must be specified/)
        end
      end

      context 'when no file is being uploaded' do
        before(:each) do
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(nil)
        end

        it 'returns a corresponding error' do
          expect(Bits::BlobstoreFactory).to_not receive(:new)

          put "/buildpacks/#{buildpack_guid}", upload_body, headers

          expect(last_response.status).to eq(400)
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(290002)
          expect(json['description']).to match(/a file must be provided/)
        end
      end

      context 'when a non-zip file is being uploaded' do
        let(:upload_body) {{ buildpack: non_zip_file }}

        it 'returns a corresponding error' do
          allow_any_instance_of(UploadParams).to receive(:original_filename).and_return('invalid.tar')
          put "/buildpacks/#{buildpack_guid}", upload_body, headers

          expect(last_response.status).to eql 400
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(290002)
          expect(json['description']).to match(/only zip files allowed/)
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          filepath = non_zip_file.tempfile.path
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(filepath)
          allow_any_instance_of(UploadParams).to receive(:original_filename).and_return(zip_filename)
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(File.exist?(filepath)).to be_falsy
        end
      end

      context 'when the blobstore copy fails' do
        before(:each) do
          allow_any_instance_of(Blobstore::Client).to receive(:cp_to_blobstore).and_raise('some error')
        end

        it 'return HTTP status 500' do
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(last_response.status).to eq(500)
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
          allow_any_instance_of(UploadParams).to receive(:original_filename).and_return(zip_filename)
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(File.exist?(zip_filepath)).to be_falsy
        end
      end

      context 'when the blobstore factory fails' do
        before(:each) do
          allow(BlobstoreFactory).to receive(:new).and_raise('some error')
        end

        it 'return HTTP status 500' do
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(last_response.status).to eq(500)
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
          allow_any_instance_of(UploadParams).to receive(:original_filename).and_return(zip_filename)
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(File.exist?(zip_filepath)).to be_falsy
        end
      end
    end

    describe 'GET /buildpacks/:guid' do
      let(:download_url) { 'some-url' }

      let(:blobs) { [ blob ] }

      let(:blob) do
        blob = double(Bits::Blobstore::Blob)
        allow(blob).to receive(:download_url).and_return(download_url)
        blob
      end

      let(:blobstore) do
        blobstore = double(Bits::Blobstore::Client)
        allow(blobstore).to receive(:blobs_for_key_prefix).with(buildpack_guid).and_return(blobs)
        blobstore
      end

      before(:each) do
        allow_any_instance_of(Bits::BlobstoreFactory).to receive(:create_buildpack_blobstore).and_return(blobstore)
      end

      it 'instantiates the blobstore factory using the config' do
        expect(Bits::BlobstoreFactory).to receive(:new).with(config).once
        get "/buildpacks/#{buildpack_guid}", headers
      end

      it 'creates the buildpack blobstore using the blobstore factory' do
        expect_any_instance_of(Bits::BlobstoreFactory).to receive(:create_buildpack_blobstore).once
        get "/buildpacks/#{buildpack_guid}", headers
      end

      it 'finds the blob inside the blobstore using the correct guid' do
        expect(blobstore).to receive(:blobs_for_key_prefix).with(buildpack_guid)
        get "/buildpacks/#{buildpack_guid}", headers
      end

      it 'checks whether the blobstore is local' do
        expect(blobstore).to receive(:local?).once
        get "/buildpacks/#{buildpack_guid}", headers
      end

      context 'when the blobstore is local' do
        before(:each) do
          allow(blobstore).to receive(:local?).and_return(true)
        end

        context 'and we are using nginx' do
          let(:use_nginx) { true }

          it 'returns HTTP status code 200' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.status).to eq(200)
          end

          it 'sets the X-Accel-Redirect response header' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.headers).to include('X-Accel-Redirect' => download_url)
          end

          it 'gets the download_url from the blob' do
            expect(blob).to receive(:download_url).once
            get "/buildpacks/#{buildpack_guid}", headers
          end
        end

        context 'and we are not using nginx' do
          let(:use_nginx) { false }

          before(:each) do
            allow(blob).to receive(:local_path).and_return(zip_filepath)
          end

          it 'returns HTTP status code 200' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.status).to eq(200)
          end

          it 'sets the right Content-Type header' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.headers).to include('Content-Type' => 'application/zip')
          end

          it 'sets the right Content-Length header' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.headers).to include('Content-Length' => File.size(zip_filepath).to_s)
          end

          it 'returns the file contents in the response body' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.body).to eq(File.open(zip_filepath, 'rb').read)
          end

          it 'does not set the X-Accel-Redirect response header' do
            get "/buildpacks/#{buildpack_guid}", headers
            expect(last_response.headers).to_not include('X-Accel-Redirect')
          end

          it 'gets the local_path from the blob' do
            expect(blob).to receive(:local_path).once
            get "/buildpacks/#{buildpack_guid}", headers
          end
        end
      end

      context 'when the blobstore is remote' do
        before(:each) do
          allow(blobstore).to receive(:local?).and_return(false)
        end

        it 'returns HTTP status code 302' do
          get "/buildpacks/#{buildpack_guid}", headers
          expect(last_response.status).to eq(302)
        end

        it 'sets the location header to the correct value' do
          get "/buildpacks/#{buildpack_guid}", headers
          expect(last_response.headers).to include('Location' => download_url)
        end
      end

      context 'when the buildpack does not exist' do
        let(:blob) { nil }

        it 'returns a corresponding error' do
          get "/buildpacks/#{buildpack_guid}", headers

          expect(last_response.status).to eq(404)
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(10000)
          expect(json['description']).to match(/Unknown request/)
        end
      end
    end
  end
end
