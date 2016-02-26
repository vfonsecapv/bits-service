require 'spec_helper'

describe 'app_stash endpoint', type: :integration do
  before(:all) do
    @root_dir = Dir.mktmpdir

    config = {
      app_stash: {
        directory_key: 'app_stash',
        fog_connection: {
          provider: 'local',
          local_root: @root_dir
        }
      },
      nginx: {
        use_nginx: false
      }
    }

    start_server(config)
  end

  after(:all) do
    stop_server
    FileUtils.rm_rf(@root_dir)
  end

  after(:each) do
    FileUtils.rm_rf(@root_dir)
    @root_dir = Dir.mktmpdir
  end

  let(:zip_filepath) { File.expand_path('../../fixtures/integration/app.zip', __FILE__) }
  let(:app_rb_sha) { '8b381f8864b572841a26266791c64ae97738a659' }
  let(:lib_rb_sha) { '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5' }

  describe 'POST /app_stash/entries' do
    let(:request_body) { { application: File.new(zip_filepath) } }

    it 'returns 201 status' do
      response = make_post_request('/app_stash/entries', request_body)
      expect(response.code).to eq(201)
    end

    it 'stores all the files from the zip based in their SHAs' do
      make_post_request('/app_stash/entries', request_body)

      app_rb = blob_path(@root_dir, 'app_stash', app_rb_sha)
      expect(File.exist?(app_rb)).to eq(true)

      lib_rb = blob_path(@root_dir, 'app_stash', lib_rb_sha)
      expect(File.exist?(lib_rb)).to eq(true)
    end

    context 'when the file is not a valid zip' do
      let(:zip_filepath) { File.expand_path('../../fixtures/integration/invalid.zip', __FILE__) }

      it 'returns 400 status' do
        response = make_post_request('/app_stash/entries', request_body)
        expect(response.code).to eq(400)
      end

      it 'returns an json describing the issue' do
        response = make_post_request('/app_stash/entries', request_body)
        description = JSON.parse(response.body)['description']
        expect(description).to match(/The app upload is invalid: Unzipping had errors/)
      end
    end

    context 'when the file is missing' do
      let(:request_body) { Hash.new }

      it 'returns 400 status' do
        response = make_post_request('/app_stash/entries', request_body)
        expect(response.code).to eq(400)
      end

      it 'returns an json describing the issue' do
        response = make_post_request('/app_stash/entries', request_body)
        description = JSON.parse(response.body)['description']
        expect(description).to match(/The app upload is invalid: missing key `application`/)
      end
    end
  end

  describe 'POST /app_stash/matches' do
    subject(:response) { make_post_request('/app_stash/matches', request_body, content_type: :json) }

    let(:existing_shas) do
      [app_rb_sha, lib_rb_sha]
    end

    let(:non_existing_shas) do
      ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb']
    end

    before do
      zip_filepath = File.expand_path('../../fixtures/integration/app.zip', __FILE__)
      request_body = { application: File.new(zip_filepath)  }
      make_post_request('/app_stash/entries', request_body)
    end

    def build_request_body(shas_array)
      shas_array.map { |sha| { sha1: sha, size: 123 } }.to_json
    end

    context 'when none of the resources exists in the stash' do
      let(:request_body) { build_request_body(non_existing_shas) }

      it 'returns HTTP status 200' do
        expect(response.code).to eq(200)
      end

      it 'reports no matches' do
        payload = JSON.parse(response.body)
        expect(payload).to be_a(Array)
        expect(payload).to be_empty
      end
    end

    context 'when some but not all of the resources exist in the stash' do
      let(:request_body) { build_request_body(non_existing_shas + existing_shas) }

      it 'returns HTTP status 200' do
        expect(response.code).to eq(200)
      end

      it 'reports only the existing resources as matches' do
        expect(response.body).to eq(build_request_body(existing_shas))
      end
    end

    context 'when all resources exist in the stash' do
      let(:request_body) { build_request_body(existing_shas) }

      it 'returns HTTP status 200' do
        expect(response.code).to eq(200)
      end

      it 'reports all resources as matches' do
        expect(response.body).to eq(request_body)
      end
    end

    context 'when the body is empty' do
      let(:request_body) { nil }

      it 'returns HTTP status 400' do
        expect(response.code).to eq(400)
      end

      it 'returns a corresponding error' do
        description = JSON.parse(response.body)['description']
        expect(description).to match(/Request invalid due to parse error:/)
      end
    end

    context 'when the body is invalid JSON' do
      let(:request_body) { 'some-invalid-json' }

      it 'returns HTTP status 400' do
        expect(response.code).to eq(400)
      end

      it 'returns a corresponding error' do
        description = JSON.parse(response.body)['description']
        expect(description).to match(/Request invalid due to parse error:/)
      end
    end

    context 'when the body is not a JSON list' do
      let(:request_body) { { foo: 'bar' }.to_json }

      it 'returns HTTP status 422' do
        expect(response.code).to eq(422)
      end

      it 'returns a corresponding error' do
        description = JSON.parse(response.body)['description']
        expect(description).to match(/The request is semantically invalid:/)
      end
    end

    context 'when none of the entries has a digest' do
      let(:request_body) { [{ size: 10 }].to_json }

      it 'returns HTTP status 200' do
        expect(response.code).to eq(200)
      end

      it 'returns an empty JSON list' do
        payload = JSON.parse(response.body)
        expect(payload).to be_a(Array)
        expect(payload).to be_empty
      end
    end
  end

  describe 'POST /app_stash/bundles' do
    context 'with temp download folder' do
      before :each do
        @download_dir = Dir.mktmpdir
      end

      after(:each) do
        FileUtils.rm_rf(@download_dir)
      end

      before do
        zip_filepath = File.expand_path('../../fixtures/integration/app.zip', __FILE__)
        request_body = { application: File.new(zip_filepath)  }
        make_post_request('/app_stash/entries', request_body)
      end

      subject(:response) { make_post_request('/app_stash/bundles', request_body, content_type: :json) }
      let(:request_body) { request_payload.to_json }

      def write_response_body_to_file(response)
        download_zip_path = "#{@download_dir}/result.zip"
        File.open(download_zip_path, 'w') do |w|
          w.write(response.body)
        end
        download_zip_path
      end

      shared_examples 'bundles endpoint' do
        it 'returns HTTP status 200' do
          expect(response.code).to eq(200)
        end

        it 'returns an application package' do
          download_zip_path = write_response_body_to_file(response)

          FileUtils.mkdir_p (unzip_path = "#{@download_dir}/unzip")

          BitsService::SafeZipper.unzip!(download_zip_path, unzip_path)

          unzipped_files = Dir[File.join(unzip_path, '**', '*')].reject{ |f| File.directory?(f) }.sort
          expected_files = request_payload.map { |spec| File.join(unzip_path, spec[:fn])}.sort
          expect(unzipped_files).to eq(expected_files)

          request_payload.each do |spec|
            unzipped_file_path = File.join(unzip_path, spec[:fn])
            expect(BitsService::Digester.new.digest_path(unzipped_file_path)).to eq(spec[:sha1])
          end
        end
      end

      context 'a single file' do
        let(:request_payload) do
          [
            { fn: "init.rb", sha1: app_rb_sha }
          ]
        end

        it_behaves_like 'bundles endpoint'
      end

      context 'multiple files' do
        let(:request_payload) do
          [
            { fn: "init.rb", sha1: app_rb_sha },
            { fn: "lib.rb", sha1: lib_rb_sha },
            { fn: "another_one.rb", sha1: lib_rb_sha }
          ]
        end

        it_behaves_like 'bundles endpoint'
      end

      context 'folders and subfolders' do
        let(:request_payload) do
          [
            { fn: "init.rb", sha1: app_rb_sha },
            { fn: "some-folder/lib.rb", sha1: lib_rb_sha },
            { fn: "another-folder/inside/another_one.rb", sha1: lib_rb_sha },
            { fn: "some-folder/subfolder/app.rb", sha1: app_rb_sha }
          ]
        end

        it_behaves_like 'bundles endpoint'
      end

      context 'when the blobstore does not have an entry' do
        let(:request_payload) do
          [
            { fn: "init.rb", sha1: app_rb_sha },
            { fn: "lib.rb", sha1: 'i-do-not-exist' },
            { fn: "another_one.rb", sha1: lib_rb_sha }
          ]
        end

        it 'returns HTTP status 404' do
          expect(response.code).to eq(404)
        end

        it 'returns a corresponding error' do
          description = JSON.parse(response.body)['description']
          expect(description).to match(/Unknown request/)
        end
      end

      context 'when the body is empty' do
        let(:request_body) { nil }

        it 'returns HTTP status 400' do
          expect(response.code).to eq(400)
        end

        it 'returns a corresponding error' do
          description = JSON.parse(response.body)['description']
          expect(description).to match(/Request invalid due to parse error:/)
        end
      end

      context 'when the body is invalid JSON' do
        let(:request_body) { 'some-invalid-json' }

        it 'returns HTTP status 400' do
          expect(response.code).to eq(400)
        end

        it 'returns a corresponding error' do
          description = JSON.parse(response.body)['description']
          expect(description).to match(/Request invalid due to parse error:/)
        end
      end

      context 'when the body is not a JSON list' do
        let(:request_body) { { foo: 'bar' }.to_json }

        it 'returns HTTP status 422' do
          expect(response.code).to eq(422)
        end

        it 'returns a corresponding error' do
          description = JSON.parse(response.body)['description']
          expect(description).to match(/The request is semantically invalid:/)
        end
      end
    end
  end
end
