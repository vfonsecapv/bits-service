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

        destination_path = Dir.mktmpdir('app_stash')
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

      post '/app_stash/bundles' do
        begin
          request.body.rewind
          request_payload = JSON.parse request.body.read
        rescue JSON::ParserError => e
          fail Errors::ApiError.new_from_details('MessageParseError', e.message)
        end

        unless request_payload.is_a?(Array) && !request_payload.empty?
          fail Errors::ApiError.new_from_details('UnprocessableEntity', 'must be a non-empty array.')
        end

        destination_path = Dir.mktmpdir('app_stash')

        request_payload.each do |resource|
          sha1 = resource['sha1']
          unless sha1 && sha1.to_s != ''
            fail Errors::ApiError.new_from_details('UnprocessableEntity', 'key `sha1` missing or empty')
          end

          fn = resource['fn']
          unless fn && fn.to_s != ''
            fail Errors::ApiError.new_from_details('UnprocessableEntity', 'key `fn` missing or empty')
          end

          unless app_stash_blobstore.exists?(sha1)
            fail Errors::ApiError.new_from_details('ResourceNotFound', "#{sha1} not found")
          end

          app_stash_blobstore.download_from_blobstore(sha1, File.join(destination_path, fn))
        end

        output_path = File.join(Dir.mktmpdir('app_stash'), 'bundle.zip')
        SafeZipper.zip(destination_path, output_path)
        FileUtils.rm_rf(destination_path)

        stream do |out|
          begin
            out << File.new(output_path).read
          ensure
            FileUtils.rm_r(output_path)
          end
        end
      end
    end
  end
end
