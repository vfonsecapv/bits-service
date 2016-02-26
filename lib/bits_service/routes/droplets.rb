require_relative './base'

module BitsService
  module Routes
    class Droplets < Base
      post '/droplets' do
        begin
          uploaded_filepath = upload_params.upload_filepath('droplet')
          fail Errors::ApiError.new_from_details('DropletUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          guid = SecureRandom.uuid
          droplet_blobstore.cp_to_blobstore(uploaded_filepath, guid)
          json 201, { guid: guid }
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      get '/droplets/:guid' do |guid|
        blob = droplet_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        if droplet_blobstore.local?
          if use_nginx?
            return [200, { 'X-Accel-Redirect' => blob.download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.download_url }, nil]
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
