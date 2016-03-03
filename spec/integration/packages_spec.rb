require 'spec_helper'

describe 'packages resource', type: :integration do
  before(:all) do
    @root_dir = Dir.mktmpdir

    config = {
      packages: {
        directory_key: 'packages',
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

  describe 'POST /packages' do
    let(:packages_endpoint) { '/packages' }
    let(:upload_body) { { package: Tempfile.new('package.zip') } }

    it 'returns HTTP status 201' do
      response = make_post_request(packages_endpoint, upload_body)
      expect(response.code).to eq 201
    end

    it 'stores the package in the package blobstore' do
      response = make_post_request(packages_endpoint, upload_body)
      json_response = JSON.parse(response.body)

      expected_path = blob_path(@root_dir, 'packages', json_response['guid'])
      expect(File).to exist(expected_path)
    end

    context 'when the package attachment is missing' do
      it 'returns HTTP status 400' do
        response = make_post_request(packages_endpoint, {})
        expect(response.code).to eq 400
      end

      it 'returns an error message' do
        response = make_post_request(packages_endpoint, {})
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'The package upload is invalid: a file must be provided'
      end
    end
  end
end
