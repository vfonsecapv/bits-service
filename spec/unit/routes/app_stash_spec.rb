require 'spec_helper'

module BitsService
  describe Routes::AppStash do
    let(:blobstore) { double(Blobstore::Client) }
    before do
      allow_any_instance_of(Routes::AppStash).to receive(:app_stash_blobstore).and_return(blobstore)
    end

    describe 'POST /app_stash/entries' do
      let(:tmp_dir) { '/path/to/tmp/dir' }
      let(:headers) { Hash.new }
      let(:zip_filepath) { '/path/to/zip/file' }
      let(:request_body) { { application: 'something' } }

      before do
        allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
        allow(Dir).to receive(:mktmpdir).and_return(tmp_dir)
        allow(SafeZipper).to receive(:unzip!)
        allow(blobstore).to receive(:cp_r_to_blobstore)
        allow(FileUtils).to receive(:rm_r)
      end

      it 'returns HTTP status 201' do
        post '/app_stash/entries', request_body, headers
        expect(last_response.status).to eq(201)
      end

      it 'unzips the uploaded zip file' do
        expect(SafeZipper).to receive(:unzip!).with(zip_filepath, tmp_dir)
        post '/app_stash/entries', request_body, headers
      end

      it 'uploads the unzipped app files to the blobstore' do
        expect(blobstore).to receive(:cp_r_to_blobstore).with(tmp_dir)
        post '/app_stash/entries', request_body, headers
      end

      it 'removes the temporary folder' do
        expect(FileUtils).to receive(:rm_r).with(tmp_dir)
        post '/app_stash/entries', request_body, headers
      end

      context 'when the upload_filepath is nil' do
        before(:each) do
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(nil)
        end

        it 'returns HTTP status 400' do
          post '/app_stash/entries', request_body, headers
          expect(last_response.status).to eq(400)
        end

        it 'returns a corresponding error' do
          post '/app_stash/entries', request_body, headers
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(160001)
          expect(json['description']).to eq('The app upload is invalid: missing key `application`')
        end

        it 'does not create a temporary dir' do
          expect(Dir).to_not receive(:mktmpdir)
          post '/app_stash/entries', request_body, headers
        end
      end

      context 'when the SafeZipper raises an error' do
        before do
          allow(SafeZipper).to receive(:unzip!).and_raise(SafeZipper::Error.new('failed here'))
        end

        it 'returns HTTP status 400' do
          post '/app_stash/entries', request_body, headers
          expect(last_response.status).to eq(400)
        end

        it 'returns a corresponding error' do
          post '/app_stash/entries', request_body, headers
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(160001)
          expect(json['description']).to eq('The app upload is invalid: failed here')
        end

        it 'removes the temporary folder' do
          expect(FileUtils).to receive(:rm_r).with(tmp_dir)
          post '/app_stash/entries', request_body, headers
        end
      end

      context 'when copying the files to the blobstorew fails' do
        before do
          allow(blobstore).to receive(:cp_r_to_blobstore).and_raise(StandardError.new('failed here'))
        end

        it 'return HTTP status 500' do
          post '/app_stash/entries', request_body, headers
          expect(last_response.status).to eq(500)
        end

        it 'removes the temporary folder' do
          expect(FileUtils).to receive(:rm_r).with(tmp_dir)
          post '/app_stash/entries', request_body, headers
        end
      end
    end
  end
end
