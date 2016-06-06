require_relative './base'

module BitsService
  module Routes
    class Droplets < Base
      put '/droplets/:guid' do |guid|
        begin
          uploaded_filepath = upload_params.upload_filepath('droplet')
          fail Errors::ApiError.new_from_details('DropletUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          droplet_blobstore.cp_to_blobstore(uploaded_filepath, guid)
          status 201
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      get '/droplets/:guid' do |guid|
        blob = droplet_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        if droplet_blobstore.local?
          if use_nginx?
            return [200, { 'X-Accel-Redirect' => blob.internal_download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.public_download_url }, nil]
        end
      end

      delete '/droplets/:guid' do |guid|
        blob = droplet_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob
        droplet_blobstore.delete_blob(blob)
        status 204
      end
    end
  end
end
