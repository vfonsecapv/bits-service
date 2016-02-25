require 'spec_helper'

describe 'app_cache resource', type: :integration do
  before(:all) do
    @root_dir = Dir.mktmpdir

    config = {
      app_cache: {
        directory_key: 'app_cache',
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

  describe 'PUT /app_cache' do
    let(:zip_filepath) { File.expand_path('../../fixtures/integration/app.zip', __FILE__) }
    let(:request_body) { { application: File.new(zip_filepath) } }

    it 'returns 201 status' do
      response = make_put_request('/app_cache', request_body)
      expect(response.code).to eq(201)
    end

    it 'stores all the files from the zip based in their SHAs' do
      make_put_request('/app_cache', request_body)

      app_rb = blob_path(@root_dir, 'app_cache', '8b381f8864b572841a26266791c64ae97738a659')
      expect(File.exist?(app_rb)).to eq(true)

      lib_rb = blob_path(@root_dir, 'app_cache', '594eb15515c89bbfb0874aa4fd4128bee0a1d0b5')
      expect(File.exist?(lib_rb)).to eq(true)
    end

    context 'when the file is not a valid zip' do
      let(:zip_filepath) { File.expand_path('../../fixtures/integration/invalid.zip', __FILE__) }

      it 'returns 400 status' do
        response = make_put_request('/app_cache', request_body)
        expect(response.code).to eq(400)
      end

      it 'returns an json describing the issue' do
        response = make_put_request('/app_cache', request_body)
        description = JSON.parse(response.body)['description']
        expect(description).to match(/The app upload is invalid: Unzipping had errors/)
      end
    end

    context 'when the file is missing' do
      let(:request_body) { Hash.new }

      it 'returns 400 status' do
        response = make_put_request('/app_cache', request_body)
        expect(response.code).to eq(400)
      end

      it 'returns an json describing the issue' do
        response = make_put_request('/app_cache', request_body)
        description = JSON.parse(response.body)['description']
        expect(description).to match(/The app upload is invalid: missing key `application`/)
      end
    end
  end
end
