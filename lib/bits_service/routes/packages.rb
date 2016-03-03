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

      get '/packages/:guid' do
        begin
          guid = params[:guid]
          fail Errors::ApiError.new_from_details('NotFound', guid) unless packages_blobstore.exists?(guid)
          unless packages_blobstore.local?
            return [302, { 'Location' => packages_blobstore.download_uri(guid) }, nil]
          end
          if use_nginx?
            return [200, { 'X-Accel-Redirect' =>  packages_blobstore.download_uri(guid) }, nil]
          end
          temp_file = Tempfile.new(guid)
          packages_blobstore.download_from_blobstore(guid, temp_file.path)
          send_file temp_file.path
        end
      end
    end
  end
end
