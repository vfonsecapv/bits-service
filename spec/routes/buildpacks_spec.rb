require 'spec_helper'
require 'securerandom'

describe Bits::Routes::Buildpacks do

  let(:headers) { Hash.new }

  let(:zip_filepath) { File.join(Dir.mktmpdir, 'file.zip')}
  let(:buildpack_guid) { SecureRandom.uuid }

  let(:zip_file) do
    TestZip.create(zip_filepath, 1, 1024)
    Rack::Test::UploadedFile.new(File.new(zip_filepath))
  end

  let(:upload_body) { { buildpack: zip_file, buildpack_name: zip_file.path } }

  context '/buildpacks/:guid' do
    it 'returns a HTTP status 201 (CREATED)' do
      put "/buildpacks/#{buildpack_guid}", upload_body, headers
      expect(last_response.status).to eq(201)
    end
  end
end
