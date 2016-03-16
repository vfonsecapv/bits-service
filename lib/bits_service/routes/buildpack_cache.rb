require_relative './base'

module BitsService
  module Routes
    class BuildpackCache < Base
      post '/buildpack_cache/:app_guid/:stack_name' do |app_guid, stack_name|
        begin
          uploaded_filepath = upload_params.upload_filepath('buildpack_cache')
          fail Errors::ApiError.new_from_details('BuildpackCacheBitsUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          buildpack_cache_blobstore.cp_to_blobstore(uploaded_filepath, key(app_guid, stack_name))

          status 201
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      get '/buildpack_cache/:app_guid/:stack_name' do |app_guid, stack_name|
        cache_key = key(app_guid, stack_name)
        blob = buildpack_cache_blobstore.blob(cache_key)
        fail Errors::ApiError.new_from_details('NotFound', cache_key) unless blob

        if buildpack_cache_blobstore.local?
          if use_nginx?
            return [200, { 'X-Accel-Redirect' => blob.download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.download_url }, nil]
        end
      end

      private

      def key(app_guid, stack_name)
        "#{app_guid}/#{stack_name}"
      end
    end
  end
end
