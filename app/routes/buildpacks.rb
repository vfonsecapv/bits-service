module Bits
  module Routes
    class Buildpacks < Sinatra::Application
      configure do
        set :show_exceptions, :after_handler

        Errors::ApiError.setup_i18n(Dir[File.expand_path('../../vendor/errors/i18n/*.yml', __FILE__)], :en)
      end

      put '/buildpacks/:guid' do | guid |
        begin
          upload_params = UploadParams.new(params, use_nginx: use_nginx)

          uploaded_filepath = upload_params.upload_filepath('buildpack')
          original_filename = upload_params.original_filename('buildpack')
          raise Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'a filename must be specified') if original_filename.to_s == ''
          raise Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'only zip files allowed') unless File.extname(original_filename) == '.zip'
          raise Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

          sha = Digester.new.digest_path(uploaded_filepath)
          destination_key = "#{guid}_#{sha}"

          blobstore = BlobstoreFactory.new(config).create_buildpack_blobstore
          blobstore.cp_to_blobstore(uploaded_filepath, destination_key)

          status 201
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      get '/buildpacks/:guid' do | guid |
        blobstore = BlobstoreFactory.new(config).create_buildpack_blobstore
        blob = blobstore.blobs_for_key_prefix(guid).first
        raise Errors::ApiError.new_from_details('NotFound', guid) unless blob

        if blobstore.local?
          if use_nginx
            return [200, { 'X-Accel-Redirect' => blob.download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.download_url }, nil]
        end
      end

      error Errors::ApiError do |error|
        halt error.response_code, {description: error.message, code: error.code}.to_json
      end

      private

      def use_nginx
        config[:nginx][:use_nginx]
      end
    end
  end
end
