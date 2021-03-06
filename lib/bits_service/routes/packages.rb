require_relative './base'

module BitsService
  module Routes
    class Packages < Base
      put '/packages/:guid' do |guid|
        uploaded_filepath = upload_params.upload_filepath('package')
        return create_from_upload(uploaded_filepath, guid) if uploaded_filepath

        source_guid = parsed_body['source_guid']
        return create_as_duplicate(source_guid, guid) if source_guid

        fail Errors::ApiError.new_from_details('InvalidPackageSource')
      end

      get '/packages/:guid' do |guid|
        blob = packages_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        return [302, { 'Location' => blob.public_download_url }, nil] unless packages_blobstore.local?
        return [200, { 'X-Accel-Redirect' => blob.internal_download_url }, nil] if use_nginx?

        return send_file blob.local_path
      end

      delete '/packages/:guid' do |guid|
        blob = packages_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        packages_blobstore.delete_blob(blob)
        status 204
      end

      def create_from_upload(uploaded_filepath, target_guid)
        fail Errors::ApiError.new_from_details('PackageUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s.empty?
        packages_blobstore.cp_to_blobstore(uploaded_filepath, target_guid)
        status 201
      ensure
        FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
      end

      def create_as_duplicate(source_guid, target_guid)
        blob = packages_blobstore.blob(source_guid)
        fail Errors::ApiError.new_from_details('NotFound', source_guid) unless blob

        packages_blobstore.cp_file_between_keys(source_guid, target_guid)
        status 201
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
