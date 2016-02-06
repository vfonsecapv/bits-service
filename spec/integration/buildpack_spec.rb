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

  let(:data) { { buildpack: zip_file } }

  it 'returns HTTP status 201' do
    response = make_put_request("/buildpacks/#{guid}", data)
    expect(response.code).to eq 201
  end
end
