require 'spec_helper'

describe 'buildpack_cache resource', type: :integration do
  before(:all) do
    @root_dir = Dir.mktmpdir

    config = {
      buildpack_cache: {
        directory_key: 'directory-key',
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
    FileUtils.rm_rf(File.dirname(zip_filepath))
    FileUtils.rm_rf(@root_dir)
    @root_dir = Dir.mktmpdir
  end

  let(:zip_filepath) { File.join(Dir.mktmpdir, 'file.zip') }

  let(:zip_file) do
    TestZip.create(zip_filepath, 1, 1024)
    File.new(zip_filepath)
  end

  let(:upload_body) { { buildpack_cache: zip_file } }

  let(:resource_path) do
    "/buildpack_cache/#{key}"
  end

  let(:key) do
    guid = SecureRandom.uuid
    "#{guid}/some-stack-name"
  end

  def blobstore_path(key)
    blob_path(@root_dir, 'directory-key', key)
  end

  describe 'POST /buildpack_cache' do
    it 'returns HTTP status 201' do
      response = make_post_request(resource_path, upload_body)
      expect(response.code).to eq 201
    end

    it 'correctly stores the file in the blob store' do
      make_post_request(resource_path, upload_body)

      expected_path = blobstore_path(key)
      expect(File).to exist(expected_path)
    end

    context 'when an empty request body is being sent' do
      let(:upload_body) { {} }

      it 'returns HTTP status 400' do
        response = make_post_request(resource_path, upload_body)
        expect(response.code).to eq 400
      end

      it 'returns the expected error description' do
        response = make_post_request(resource_path, upload_body)
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'The buildpack_cache upload is invalid: a file must be provided'
      end
    end
  end

  describe 'GET /buildpack_cache/:app_guid/:stack_name' do
    context 'when the buildpack cache exists' do
      before do
        make_post_request(resource_path, upload_body)
      end

      it 'returns HTTP status code 200' do
        response = make_get_request(resource_path)
        expect(response.code).to eq 200
      end

      it 'returns the correct buildpack cache' do
        response = make_get_request(resource_path)
        expect(response.body).to eq(File.open(zip_filepath, 'rb').read)
      end
    end

    context 'when the buildpack cache does not exist' do
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

    context 'when the stack name is missing' do
      it 'returns HTTP status code 404' do
        response = make_get_request('/buildpack_cache/not-here')
        expect(response.code).to eq 404
      end
    end
  end
end
