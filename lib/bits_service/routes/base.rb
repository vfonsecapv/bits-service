require_relative '../errors/api_error'

module BitsService
  module Routes
    class Base < Sinatra::Application
      configure do
        set :show_exceptions, :after_handler

        Errors::ApiError.setup_i18n(Dir[File.expand_path('../../vendor/errors/i18n/*.yml', __FILE__)], :en)
      end

      before do
        logger.info(
          'request.started',
          path: request.path,
          method: request.request_method,
          vcap_request_id: request.env['HTTP_X_VCAP_REQUEST_ID']
        )
      end

      after do
        logger.info(
          'request.ended',
          response_code: response.status,
          vcap_request_id: request.env['HTTP_X_VCAP_REQUEST_ID']
        )
      end

      error Errors::ApiError do |error|
        logger.error('error', description: error.message, code: error.code)
        halt error.response_code, { description: error.message, code: error.code }.to_json
      end

      error StandardError do |error|
        logger.error('error', description: error.message, stack_trace: error.backtrace)
        return halt 500 if ENV['RACK_ENV'] == 'production'

        halt 500, { description: error.message, stack_trace: error.backtrace }.to_json
      end

      private

      def json(status_code, body)
        content_type :json
        status status_code
        body.to_json
      end
    end
  end
end
