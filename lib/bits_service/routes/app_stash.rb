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

      post '/app_stash/matches' do
        begin
          request.body.rewind
          request_payload = JSON.parse request.body.read
        rescue JSON::ParserError => e
          fail Errors::ApiError.new_from_details('MessageParseError', e.message)
        end

        unless request_payload.is_a?(Array)
          fail Errors::ApiError.new_from_details('UnprocessableEntity', 'must be an array.')
        end

        response_payload = request_payload.select do |resource|
          resource.key?('sha1') && app_stash_blobstore.exists?(resource['sha1'])
        end

        json 200, response_payload
      end
    end
  end
end
