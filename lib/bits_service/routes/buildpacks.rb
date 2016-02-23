module BitsService
  module Routes
    class Buildpacks < Base
      post '/buildpacks' do
        begin
          upload_params = UploadParams.new(params, use_nginx: use_nginx?)

          uploaded_filepath = upload_params.upload_filepath('buildpack')
          original_filename = upload_params.original_filename('buildpack')
          fail Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'a filename must be specified') if original_filename.to_s == ''
          fail Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'only zip files allowed') unless File.extname(original_filename) == '.zip'
          fail Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          digest = Digester.new.digest_path(uploaded_filepath)
          guid = SecureRandom.uuid

          blobstore = Blobstore::Factory.new(config).create_buildpack_blobstore
          blobstore.cp_to_blobstore(uploaded_filepath, guid)

          json 201, { guid: guid, digest: digest }
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      get '/buildpacks/:guid' do |guid|
        blobstore = Blobstore::Factory.new(config).create_buildpack_blobstore
        blob = blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        if blobstore.local?
          if use_nginx?
            return [200, { 'X-Accel-Redirect' => blob.download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.download_url }, nil]
        end
      end

      delete '/buildpacks/:guid' do |guid|
        blobstore = Blobstore::Factory.new(config).create_buildpack_blobstore
        blob = blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob
        blobstore.delete_blob(blob)
        status 204
      end
    end
  end
end
