module Bits
  module Routes
    class Buildpacks < Sinatra::Application
      put '/buildpacks/:guid' do
        config = {
          buildpacks: {
            fog_connection: {
              provider: 'AWS',
              aws_access_key_id: 'fake_aws_key_id',
              aws_secret_access_key: 'fake_secret_access_key',
            },
          },
          nginx: {
            use_nginx: false,
          },
        }

        blobstore = BlobstoreFactory.new(config).create_buildpack_blobstore

        upload_params = UploadParams.new(params, use_nginx: config[:nginx][:use_nginx])

        source_path = upload_params.upload_filepath('buildpack')

        sha = Digester.new.digest_path(source_path)
        destination_key = "#{params[:guid]}_#{sha}"

        blobstore.cp_to_blobstore(source_path, destination_key)

        status 201
      end
    end
  end
end
