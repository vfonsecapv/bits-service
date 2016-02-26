require 'spec_helper'

module BitsService
  describe Routes::AppStash do
    let(:blobstore) { double(Blobstore::Client) }
    let(:headers) { Hash.new }
    before do
      allow_any_instance_of(Routes::AppStash).to receive(:app_stash_blobstore).and_return(blobstore)
    end

    describe 'POST /app_stash/entries' do
      let(:tmp_dir) { '/path/to/tmp/dir' }
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

      context 'when copying the files to the blobstore fails' do
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

    describe 'POST /app_stash/matches' do
      let(:request_body) { [].to_json }
      let(:headers) { { content_type: :json } }
      let(:resources) { [{ 'sha1' => 'existing' }, { 'sha1' => 'non-existing' }] }

      before(:each) do
        allow(JSON).to receive(:parse).and_return(resources)
        allow(blobstore).to receive(:exists?).with('existing').and_return(true)
        allow(blobstore).to receive(:exists?).with('non-existing').and_return(false)
      end

      it 'returns HTTP status 200' do
        post '/app_stash/matches', request_body, headers
        expect(last_response.status).to eq(200)
      end

      it 'returns a valid response body' do
        post '/app_stash/matches', request_body, headers

        allow(JSON).to receive(:parse).and_call_original
        payload = JSON.parse(last_response.body)
        expect(payload).to eq([{ 'sha1' => 'existing' }])
      end

      it 'makes sure the request payload is an Array' do
        expect(resources).to receive(:is_a?).with(Array)
        post '/app_stash/matches', request_body, headers
      end

      it 'checks whether for all resources if they exists in the blobstore' do
        expect(blobstore).to receive(:exists?).with('existing')
        expect(blobstore).to receive(:exists?).with('non-existing')

        post '/app_stash/matches', request_body, headers
      end

      context 'when the payload is not an array' do
        before do
          allow(resources).to receive(:is_a?).with(Array).and_return(false)
        end

        it 'returns HTTP status 422' do
          post '/app_stash/matches', request_body, headers
          expect(last_response.status).to eq(422)
        end

        it 'returns a corresponding error' do
          post '/app_stash/matches', request_body, headers

          allow(JSON).to receive(:parse).and_call_original
          description = JSON.parse(last_response.body)['description']

          expect(description).to match(/The request is semantically invalid:/)
        end
      end

      context 'when the parsing the request body fails' do
        before(:each) do
          allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new('failed here'))
        end

        it 'returns HTTP status 400' do
          post '/app_stash/matches', request_body, headers
          expect(last_response.status).to eq(400)
        end

        it 'returns a corresponding error' do
          post '/app_stash/matches', request_body, headers

          allow(JSON).to receive(:parse).and_call_original
          description = JSON.parse(last_response.body)['description']

          expect(description).to match(/Request invalid due to parse error:/)
        end
      end

      context 'when the blobstore call fails' do
        before(:each) do
          allow(blobstore).to receive(:exists?).and_raise(StandardError.new('failed here'))
        end

        it 'return HTTP status 500' do
          post '/app_stash/matches', request_body, headers
          expect(last_response.status).to eq(500)
        end
      end
    end

    describe 'POST /app_stash/bundles' do
      let(:request_body) { [].to_json }
      let(:headers) { { content_type: :json } }
      let(:resources) { [{ 'fn' => 'app.rb', 'sha1' => 'existing' }, { 'fn' => 'lib.rb', 'sha1' => 'existing' }] }

      let(:destination_dir) { 'mock_destination_dir' }
      let(:zip_dir) { 'mock_zip_dir' }
      let(:zip_path) { File.join(zip_dir, 'package.zip') }

      before(:each) do
        allow(JSON).to receive(:parse).and_return(resources)
        allow(blobstore).to receive(:exists?).with('existing').and_return(true)
        allow(blobstore).to receive(:exists?).with('non-existing').and_return(false)
        allow(blobstore).to receive(:download_from_blobstore)
        allow(Dir).to receive(:mktmpdir).and_return(destination_dir, zip_dir)
      end

      it 'checks if each resource exists in the blobstore' do
        expect(blobstore).to receive(:exists?).with('existing').twice
        post '/app_stash/bundles', request_body, headers
      end

      it 'downloads each resource from the blobstore' do
        expect(blobstore).to receive(:download_from_blobstore).with('existing', anything).twice
        post '/app_stash/bundles', request_body, headers
      end

      it 'zips the download directory' do
        expect(SafeZipper).to receive(:zip).with(destination_dir, zip_path)
        post '/app_stash/bundles', request_body, headers
      end

      it 'returns a file' do
      end

      it 'returns HTTP status 200' do
        allow_any_instance_of(Routes::AppStash).to receive(:send_file)
        post '/app_stash/bundles', request_body, headers
        expect(last_response.status).to eq(200)
      end

      context 'when the payload is not an array' do
        before do
          allow(resources).to receive(:is_a?).with(Array).and_return(false)
        end

        it 'returns HTTP status 422' do
          post '/app_stash/bundles', request_body, headers
          expect(last_response.status).to eq(422)
        end

        it 'returns a corresponding error' do
          post '/app_stash/bundles', request_body, headers

          allow(JSON).to receive(:parse).and_call_original
          description = JSON.parse(last_response.body)['description']

          expect(description).to match(/The request is semantically invalid:/)
        end
      end

      context 'when the payload is missing required values' do
        let(:resources) { [{ 'sha1' => 'existing' }, { 'fn' => 'lib.rb', 'sha1' => 'existing' }] }

        it 'returns HTTP status 422' do
          post '/app_stash/bundles', request_body, headers
          expect(last_response.status).to eq(422)
        end

        it 'returns a corresponding error' do
          post '/app_stash/bundles', request_body, headers

          allow(JSON).to receive(:parse).and_call_original
          description = JSON.parse(last_response.body)['description']

          expect(description).to match(/The request is semantically invalid:/)
        end
      end

      context 'when the blobstore cannot find a requested sha1' do
        let(:resources) { [{ 'fn' => 'app.rb', 'sha1' => 'existing' }, { 'fn' => 'lib.rb', 'sha1' => 'non-existing' }] }

        it 'returns HTTP status 404' do
          post '/app_stash/bundles', request_body, headers
          expect(last_response.status).to eq(404)
        end

        it 'returns a corresponding error' do
          post '/app_stash/bundles', request_body, headers

          allow(JSON).to receive(:parse).and_call_original
          description = JSON.parse(last_response.body)['description']

          expect(description).to match(/Unknown request/)
        end
      end

      context 'when the parsing the request body fails' do
        before(:each) do
          allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new('failed here'))
        end

        it 'returns HTTP status 400' do
          post '/app_stash/bundles', request_body, headers
          expect(last_response.status).to eq(400)
        end

        it 'returns a corresponding error' do
          post '/app_stash/bundles', request_body, headers

          allow(JSON).to receive(:parse).and_call_original
          description = JSON.parse(last_response.body)['description']

          expect(description).to match(/Request invalid due to parse error:/)
        end
      end

      context 'when the blobstore call fails' do
        before(:each) do
          allow(blobstore).to receive(:download_from_blobstore).and_raise(StandardError.new('failed here'))
        end

        it 'return HTTP status 500' do
          post '/app_stash/bundles', request_body, headers
          expect(last_response.status).to eq(500)
        end
      end
    end
  end
end
