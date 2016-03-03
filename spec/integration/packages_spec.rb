require 'spec_helper'

describe 'packages resource', type: :integration do
  context 'without nginx' do
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
    describe 'GET /packages/:guid' do
      let(:packages_endpoint) { '/packages' }
      context 'When package id does not exist' do
        it 'returns HTTP status 404 when id not found' do
          response = make_get_request("#{packages_endpoint}/non_existent_id")
          expect(response.code).to eq 404
        end
      end
      context 'When package exists locally without nginx' do
        let(:test_content) { 'contents of the file' }
        let(:file) { Tempfile.new('package.zip') }
        let(:upload_body) do |variable|
          file.write(test_content)
          file.close
          { package: File.new(file) }
        end
        before do
          response = make_post_request(packages_endpoint, upload_body)
          guid = JSON.parse(response.body)['guid']
          @response = make_get_request("#{packages_endpoint}/#{guid}")
        end

        it 'returns a HTTP Status 200 when valid guid is provided' do
          expect(@response.code).to eq 200
        end

        it 'returns the package when valid guid is provided' do
          expect(@response.body).to eq test_content
        end
      end
    end
  end

  context 'with nginx' do
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
          use_nginx: true
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

    describe 'GET /packages/:guid' do
      let(:packages_endpoint) { '/packages' }
      context 'When package exists locally with nginx' do
        let(:test_content) { 'contents of the file' }
        let(:file) { Tempfile.new('package.zip') }
        let(:upload_body) do |variable|
          file.write(test_content)
          file.close
          { package_path: file.path }
        end
        before do
          response = make_post_request(packages_endpoint, upload_body)
          @guid = JSON.parse(response.body)['guid']
          @response = make_get_request("#{packages_endpoint}/#{@guid}")
        end

        it 'returns a HTTP Status 200 when valid guid is provided' do
          expect(@response.code).to eq 200
        end

        it 'returns the response with appropriate headers when valid guid is provided' do
          download_url = blob_path('', 'packages', @guid)
          expect(@response.headers[:x_accel_redirect]).to eq download_url
        end
      end
    end
  end
end
