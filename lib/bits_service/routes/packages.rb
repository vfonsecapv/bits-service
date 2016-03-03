require_relative './base'

module BitsService
  module Routes
    class Packages < Base
      post '/packages' do
        begin
          uploaded_filepath = upload_params.upload_filepath('package')
          fail Errors::ApiError.new_from_details('PackageUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          guid = SecureRandom.uuid
          packages_blobstore.cp_to_blobstore(uploaded_filepath, guid)
          json 201, { guid: guid }
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end
    end
  end
end
