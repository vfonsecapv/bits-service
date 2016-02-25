require_relative './base'
require 'fileutils'

module BitsService
  module Routes
    class AppStash < Base
      post '/app_stash/entries' do
        uploaded_filepath = upload_params.upload_filepath('application')
        fail Errors::ApiError.new_from_details(
          'AppBitsUploadInvalid',
          'missing key `application`') unless uploaded_filepath

        destination_path = Dir.mktmpdir('app_cache')
        begin
          SafeZipper.unzip!(uploaded_filepath, destination_path)
          app_stash_blobstore.cp_r_to_blobstore(destination_path)
        rescue SafeZipper::Error => e
          fail Errors::ApiError.new_from_details('AppBitsUploadInvalid', e.message)
        ensure
          FileUtils.rm_r(destination_path)
        end

        status 201
      end
    end
  end
end
