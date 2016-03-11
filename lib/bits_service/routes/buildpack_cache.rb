require_relative './base'

module BitsService
  module Routes
    class BuildpackCache < Base
      post '/buildpack_cache/:app_guid/:stack_name' do |app_guid, stack_name|
        begin
          uploaded_filepath = upload_params.upload_filepath('buildpack_cache')
          fail Errors::ApiError.new_from_details('BuildpackCacheBitsUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          key = "#{app_guid}/#{stack_name}"
          buildpack_cache_blobstore.cp_to_blobstore(uploaded_filepath, key)

          status 201
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end
    end
  end
end
