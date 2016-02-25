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
end
