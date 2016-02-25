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

  describe 'POST /app_stash/entries' do
    let(:request_body) { { application: File.new(zip_filepath) } }

    it 'returns 201 status' do
      response = make_post_request('/app_stash/entries', request_body)
      expect(response.code).to eq(201)
    end

    it 'stores all the files from the zip based in their SHAs' do
      make_post_request('/app_stash/entries', request_body)

      app_rb = blob_path(@root_dir, 'app_stash', '8b381f8864b572841a26266791c64ae97738a659')
      expect(File.exist?(app_rb)).to eq(true)

      lib_rb = blob_path(@root_dir, 'app_stash', '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5')
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
      ['8b381f8864b572841a26266791c64ae97738a659', '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5']
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
end
