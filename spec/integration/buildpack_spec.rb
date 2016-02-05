require 'spec_helper'

describe 'PUT /buildpack', type: :integration do
  $config = {
    buildpacks: {
      fog_connection: {
        provider: 'local',
        local_root: '/tmp/test2',
      },
    },
    nginx: {
      use_nginx: false,
    },
  }

  before(:all) do
    start_server($config)
  end

  after(:all) do
    stop_server
  end

  after(:each) do
    FileUtils.rm_f(zip_filepath)
  end

  let(:guid) { SecureRandom.uuid }

  let(:zip_filepath) { File.join(Dir.mktmpdir, 'file.zip')}

  let(:zip_file) do
    TestZip.create(zip_filepath, 1, 1024)
    File.new(zip_filepath)
  end

  let(:data) { { buildpack: zip_file } }

  it 'returns HTTP status 201' do
    response = make_multipart_put_request("/buildpacks/#{guid}", data)
    expect(response.code).to eq 201
  end
end
