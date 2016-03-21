require_relative './base'

module BitsService
  module Routes
    class Packages < Base
      post '/packages' do
        uploaded_filepath = upload_params.upload_filepath('package')
        return create_from_upload(uploaded_filepath) if uploaded_filepath

        guid = parsed_body['source_guid']
        return create_as_duplicate(guid) if guid

        fail Errors::ApiError.new_from_details('InvalidPackageSource')
      end

      get '/packages/:guid' do |guid|
        blob = packages_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        return [302, { 'Location' => blob.download_url }, nil] unless packages_blobstore.local?
        return [200, { 'X-Accel-Redirect' => blob.download_url }, nil] if use_nginx?

        return send_file blob.local_path
      end

      delete '/packages/:guid' do |guid|
        blob = packages_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        packages_blobstore.delete_blob(blob)
        status 204
      end

      def create_from_upload(uploaded_filepath)
        fail Errors::ApiError.new_from_details('PackageUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s.empty?
        guid = SecureRandom.uuid
        packages_blobstore.cp_to_blobstore(uploaded_filepath, guid)
        json 201, { guid: guid }
      ensure
        FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
      end

      def create_as_duplicate(guid)
        blob = packages_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        new_guid = SecureRandom.uuid
        packages_blobstore.cp_file_between_keys(guid, new_guid)

        json 201, { guid: new_guid }
      end

      def parsed_body
        body = request.body.read

        if body.empty?
          {}
        else
          JSON.parse(body)
        end
      rescue JSON::ParserError => e
        fail Errors::ApiError.new_from_details('MessageParseError', e.message)
      end
    end
  end
end
