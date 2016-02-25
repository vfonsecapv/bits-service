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
    end
  end
end
