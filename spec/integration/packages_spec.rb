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
    context 'with file upload' do
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
          expect(description).to eq 'Cannot create package. The source must either be uploaded or the guid of a source app to be copied must be provided'
        end
      end
    end

    context 'with source_guid' do
      let(:body) { JSON.generate(source_guid: guid) }

      it 'returns HTTP status 201' do
        response = make_post_request(collection_path, body)
        expect(response.code).to eq 201
      end

      it 'ensures that the package is not using the same guid' do
        response = make_post_request(collection_path, body)
        json_response = JSON.parse(response.body)

        expect(json_response['guid']).to_not eq(guid)
      end

      it 'stores the package in the package blobstore' do
        response = make_post_request(collection_path, body)
        json_response = JSON.parse(response.body)

        expected_path = blob_path(@root_dir, 'packages', json_response['guid'])
        expect(File).to exist(expected_path)
        expect(File.read(expected_path)).to eq(package_contents)
      end

      context 'when the package does not exist' do
        let(:guid) { 'invalid-guid' }

        it 'returns HTTP status 404' do
          response = make_post_request(collection_path, body)
          expect(response.code).to eq 404
        end

        it 'returns an error message' do
          response = make_post_request(collection_path, body)
          description = JSON.parse(response.body)['description']
          expect(description).to eq 'Unknown request'
        end
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

  describe 'DELETE /packages/:guid' do
    context 'when the packages exists' do
      it 'returns HTTP status code 204' do
        response = make_delete_request(resource_path)
        expect(response.code).to eq 204
      end

      it 'removes the stored file' do
        expected_path = blob_path(@root_dir, 'packages', guid)

        expect {
          make_delete_request(resource_path)
        }.to change {
          File.exist?(expected_path)
        }.from(true).to(false)
      end
    end

    context 'when the droplets does not exist' do
      let(:resource_path) { '/packages/not-existing' }

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
