require 'spec_helper'

module BitsService
  module Routes
    describe Packages do
      let(:blobstore) { double(Blobstore::Client) }
      let(:headers) { Hash.new }
      before do
        allow_any_instance_of(Routes::Packages).to receive(:packages_blobstore).and_return(blobstore)
      end

      describe 'POST /packages' do
        let(:package_guid) { SecureRandom.uuid }
        let(:zip_filepath) { '/path/to/zip/file' }
        let(:request_body) { { application: 'something' } }
        let(:package_response) { { 'guid' => package_guid }  }

        before do
          allow(SecureRandom).to receive(:uuid).and_return(package_guid)
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
          allow(blobstore).to receive(:cp_to_blobstore)
          allow(FileUtils).to receive(:rm_r)
        end

        it 'returns HTTP status 201' do
          post '/packages', request_body, headers
          expect(last_response.status).to eq(201)
        end

        it 'an guid for the stored package' do
          post '/packages', request_body, headers
          response_body = last_response.body
          expect(response_body).to_not be_empty

          json = JSON.parse(last_response.body)
          expect(json).to_not be_empty
          expect(json['guid']).to eq(package_guid)
        end

        context 'when the upload_filepath is empty' do
          before(:each) do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return('')
          end

          it 'returns HTTP status 400' do
            post '/packages', request_body, headers
            expect(last_response.status).to eq(400)
          end

          it 'returns a corresponding error' do
            post '/packages', request_body, headers
            json = MultiJson.load(last_response.body)
            expect(json['description']).to eq('The package upload is invalid: a file must be provided')
          end

          it 'does not create a temporary dir' do
            expect(Dir).to_not receive(:mktmpdir)
            post '/packages', request_body, headers
          end
        end

        context 'when copying the files to the blobstore fails' do
          before do
            allow(blobstore).to receive(:cp_to_blobstore).and_raise(StandardError.new('failed here'))
          end

          it 'return HTTP status 500' do
            post '/packages', request_body, headers
            expect(last_response.status).to eq(500)
          end

          it 'removes the temporary folder' do
            expect(FileUtils).to receive(:rm_f).with(zip_filepath)
            post '/packages', request_body, headers
          end
        end
      end
      describe 'GET /packages/:guid' do
        let(:request_body) { {} }
        let(:package_response) { {}  }

        before do
          allow(blobstore).to receive(:exists?).and_return(true)
          temp_file = Tempfile.new('test_file')
          temp_file.write('Test Content')
          temp_file.close
          allow(Tempfile).to receive(:new).and_return(temp_file)
          allow(blobstore).to receive(:download_from_blobstore)
          allow(blobstore).to receive(:local?).and_return(true)
        end
        context 'Without Nginx' do
          it 'returns HTTP status 200' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.status).to eq(200)
          end

          it 'returns a valid file' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.body).to eq 'Test Content'
          end
        end
        context 'With Nginx' do
          before do
            allow_any_instance_of(Packages).to receive(:use_nginx?).and_return(true)
            allow(blobstore).to receive(:download_uri).and_return('/valid/path/to/file')
          end

          it 'returns HTTP status 200' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.status).to eq(200)
          end

          it 'returns a valid header pointing to the file' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.headers['X-Accel-Redirect']).to eq '/valid/path/to/file'
          end
        end
        context 'Blobstore is not local' do
          before do
            allow(blobstore).to receive(:download_uri).and_return('/valid/path/to/file')
            allow(blobstore).to receive(:local?).and_return(false)
          end

          it 'returns HTTP status 302' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.status).to eq(302)
          end

          it 'returns valid header pointing to the file' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.headers['Location']).to eq('/valid/path/to/file')
          end
        end

        context 'when package is not there' do
          before do
            allow(blobstore).to receive(:exists?).and_return(false)
          end

          it 'returns 404' do
            get '/packages/valid_guid', request_body, headers
            expect(last_response.status).to eq(404)
          end
        end
      end
    end
  end
end
