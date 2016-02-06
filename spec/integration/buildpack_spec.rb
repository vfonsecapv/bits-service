require 'spec_helper'

describe 'PUT /buildpack', type: :integration do
  before(:all) do
     @root_dir = Dir.mktmpdir

     config = {
      buildpacks: {
        buildpack_directory_key: 'directory-key',
        fog_connection: {
          provider: 'local',
          local_root: @root_dir,
        },
      },
      nginx: {
        use_nginx: false,
      },
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

  let(:guid) { SecureRandom.uuid }

  let(:zip_filepath) { File.join(Dir.mktmpdir, 'file.zip')}

  let(:zip_file) do
    TestZip.create(zip_filepath, 1, 1024)
    File.new(zip_filepath)
  end

  let(:zip_file_sha) { Bits::Digester.new.digest_path(zip_file) }

  let(:data) { { buildpack: zip_file } }

  it 'returns HTTP status 201' do
    response = make_put_request("/buildpacks/#{guid}", data)
    expect(response.code).to eq 201
  end

  it 'correctly stores the file in the blob store' do
    blobstore_key = "#{guid}_#{zip_file_sha}"
    blobstore_path = File.join(
      @root_dir,
      'directory-key',
      blobstore_key[0..1],
      blobstore_key[2..3],
      blobstore_key,
    )

    make_put_request("/buildpacks/#{guid}", data)

    expect(File).to exist(blobstore_path)
    expect(Bits::Digester.new.digest_path(blobstore_path)).to eq zip_file_sha
  end

  context 'when an invalid request body is being sent' do
    let(:data) { Hash.new }

    it 'returns HTTP status 400' do
      response = make_put_request("/buildpacks/#{guid}", data)
      expect(response.code).to eq 400
      expect(JSON.parse(response.body)['description']).to eq 'The buildpack upload is invalid: a file must be provided'
    end

    it 'returns the expected error description' do
      response = make_put_request("/buildpacks/#{guid}", data)
      description = JSON.parse(response.body)['description']
      expect(description).to eq 'The buildpack upload is invalid: a file must be provided'
    end
  end
end
