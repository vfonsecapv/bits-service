module Bits
  module Routes
    class Buildpacks < Sinatra::Application
      configure do
        set :show_exceptions, :after_handler

        Errors::ApiError.setup_i18n(Dir[File.expand_path('../../vendor/errors/i18n/*.yml', __FILE__)], :en)
      end

      put '/buildpacks/:guid' do
        config = YAML.load_file(ENV.fetch('BITS_CONFIG_FILE')).symbolize_keys

        begin
          upload_params = UploadParams.new(params, use_nginx: config[:nginx][:use_nginx])

          uploaded_filepath = upload_params.upload_filepath('buildpack')
          raise Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''
          raise Errors::ApiError.new_from_details('BuildpackBitsUploadInvalid', 'only zip files allowed') unless File.extname(uploaded_filepath) == '.zip'

          sha = Digester.new.digest_path(uploaded_filepath)
          destination_key = "#{params[:guid]}_#{sha}"

          blobstore = BlobstoreFactory.new(config).create_buildpack_blobstore
          blobstore.cp_to_blobstore(uploaded_filepath, destination_key)

          status 201
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      error Errors::ApiError do |error|
        halt 400, {description: error.message, code: error.code}.to_json
      end
    end
  end
end
