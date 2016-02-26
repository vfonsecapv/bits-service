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
        response_payload = request_payload.select do |resource|
          resource.key?('sha1') && app_stash_blobstore.exists?(resource['sha1'])
        end

        json 200, response_payload
      end

      post '/app_stash/bundles' do
        destination_dir = Dir.mktmpdir('app_cache')

        unless request_payload.all? { |e| e['fn'] && e['sha1'] }
          fail Errors::ApiError.new_from_details('UnprocessableEntity', 'must specify sha1 and fn for each entry')
        end

        unless request_payload.all? { |e| app_stash_blobstore.exists? e['sha1']  }
          fail Errors::ApiError.new_from_details('NotFound', 'requested sha1 not found in blob store')
        end

        request_payload.each do |file_spec|
          destination_path = File.join(destination_dir, file_spec['fn'])
          app_stash_blobstore.download_from_blobstore(file_spec['sha1'], destination_path)
        end

        zip_dir = Dir.mktmpdir('app_cache')
        zip_path = File.join(zip_dir, 'package.zip')
        SafeZipper.zip(destination_dir, zip_path)

        status 200
        send_file zip_path, type: :zip
      end

      private

      def request_payload
        return @request_payload if @request_payload
        @request_payload = JSON.parse request.body.read

        unless request_payload.is_a?(Array)
          fail Errors::ApiError.new_from_details('UnprocessableEntity', 'must be an array.')
        end

        @request_payload
      rescue JSON::ParserError => e
        fail Errors::ApiError.new_from_details('MessageParseError', e.message)
      end

    end
  end
end
