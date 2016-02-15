require 'spec_helper'

describe 'buildpacks resource', type: :integration do
  before(:all) do
    @root_dir = Dir.mktmpdir

    config = {
      buildpacks: {
        buildpack_directory_key: 'directory-key',
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
  end

  let(:zip_filepath) { File.join(Dir.mktmpdir, 'file.zip') }

  let(:zip_file) do
    TestZip.create(zip_filepath, 1, 1024)
    File.new(zip_filepath)
  end

  let(:collection_path) { '/buildpacks' }

  let(:upload_body) { { buildpack: zip_file, buildpack_name: 'original.zip' } }

  let(:zip_file_sha) { Bits::Digester.new.digest_path(zip_file) }

  let(:resource_path) do
    "/buildpacks/#{guid}"
  end

  let(:guid) do
    response = make_post_request(collection_path, upload_body)
    JSON.parse(response.body)['guid']
  end

  def blobstore_path(guid)
    File.join(
      @root_dir,
      'directory-key',
      guid[0..1],
      guid[2..3],
      guid
    )
  end

  describe 'POST /buildpack' do
    it 'returns HTTP status 201' do
      response = make_post_request(collection_path, upload_body)
      expect(response.code).to eq 201
    end

    it 'correctly stores the file in the blob store' do
      response = make_post_request(collection_path, upload_body)
      json_response = JSON.parse(response.body)

      expected_path = blobstore_path(json_response['guid'])
      expect(File).to exist(expected_path)
      expect(Bits::Digester.new.digest_path(expected_path)).to eq zip_file_sha
    end

    context 'when an empty request body is being sent' do
      let(:upload_body) { { buildpack_name: 'original.zip' } }

      it 'returns HTTP status 400' do
        response = make_post_request(collection_path, upload_body)
        expect(response.code).to eq 400
      end

      it 'returns the expected error description' do
        response = make_post_request(collection_path, upload_body)
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'The buildpack upload is invalid: a file must be provided'
      end
    end

    context 'when the original uploaded file name is missing' do
      let(:upload_body) { { buildpack: zip_file } }

      it 'returns HTTP status 400' do
        response = make_post_request(collection_path, upload_body)
        expect(response.code).to eq 400
      end

      it 'returns the expected error description' do
        response = make_post_request(collection_path, upload_body)
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'The buildpack upload is invalid: a filename must be specified'
      end
    end
  end

  describe 'GET /buildpacks/:guid' do
    context 'when the buildpack exists' do
      it 'returns HTTP status code 200' do
        response = make_get_request(resource_path)
        expect(response.code).to eq 200
      end

      it 'returns the correct bits' do
        response = make_get_request(resource_path)
        expect(response.body).to eq(File.open(zip_filepath, 'rb').read)
      end
    end

    context 'when the buildpack does not exist' do
      let(:resource_path) { '/buildpacks/not-existing' }

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

  describe 'DELETE /buildpacks/:guid' do
    context 'when the buildpack exists' do
      it 'returns HTTP status code 200' do
        response = make_delete_request(resource_path)
        expect(response.code).to eq 200
      end

      it 'removes the stored file' do
        expected_path = blobstore_path(guid)
        expect(File).to exist(expected_path)
        make_delete_request(resource_path)
        expect(File).to_not exist(expected_path)
      end
    end

    context 'when the buildpack does not exist' do
      let(:resource_path) { '/buildpacks/not-existing' }

      it 'returns HTTP status code 404' do
        response = make_delete_request(resource_path)
        expect(response.code).to eq 404
      end

      it 'returns the expected error description' do
        response = make_delete_request(resource_path)
        description = JSON.parse(response.body)['description']
        expect(description).to eq 'Unknown request'
      end
    end
  end
end
