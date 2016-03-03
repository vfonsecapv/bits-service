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
    end
  end
end
