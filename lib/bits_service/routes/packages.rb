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
        guid = params[:guid]
        blob = packages_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        return [302, { 'Location' => blob.download_url }, nil] unless packages_blobstore.local?
        return [200, { 'X-Accel-Redirect' => blob.download_url }, nil] if use_nginx?

        return send_file blob.local_path
      end
    end
  end
end
