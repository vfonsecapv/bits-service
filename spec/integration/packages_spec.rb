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

  let(:package_contents) { 'package contents' }
  let(:package) do
    Tempfile.new('package.zip').tap do |file|
      file.write(package_contents)
      file.close
    end
  end
  let(:upload_body) { { package: File.new(package.path) } }
  let(:collection_path) { '/packages' }
  let(:resource_path) { "/packages/#{guid}" }
  let(:guid) do
    response = make_post_request(collection_path, upload_body)
    JSON.parse(response.body)['guid']
  end

  describe 'POST /packages' do
    it 'returns HTTP status 201' do
      response = make_post_request(collection_path, upload_body)
      expect(response.code).to eq 201
    end

    it 'stores the package in the package blobstore' do
      response = make_post_request(collection_path, upload_body)
      json_response = JSON.parse(response.body)

      expected_path = blob_path(@root_dir, 'packages', json_response['guid'])
      expect(File).to exist(expected_path)
      expect(File.read(expected_path)).to eq(package_contents)
    end

    context 'when the package attachment is missing' do
      it 'returns HTTP status 400' do
        response = make_post_request(collection_path, {})
        expect(response.code).to eq 400
      end

      it 'returns an error message' do
        response = make_post_request(collection_path, {})
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'The package upload is invalid: a file must be provided'
      end
    end
  end

  describe 'GET /packages/:guid' do
    context 'when the package exists' do
      it 'returns HTTP status code 200' do
        response = make_get_request(resource_path)
        expect(response.code).to eq 200
      end

      it 'returns the correct bits' do
        response = make_get_request(resource_path)
        expect(response.body).to eq(File.open(package.path, 'rb').read)
      end
    end

    context 'when the droplets does not exist' do
      let(:resource_path) { '/packages/not-existing' }

      it 'returns HTTP status code 404' do
        response = make_get_request(resource_path)
        expect(response.code).to eq 404
      end

      it 'returns the expected error description' do
        response = make_get_request(resource_path)
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'Unknown request'
      end
    end
  end
end
