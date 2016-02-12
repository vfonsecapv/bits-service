module Bits
  module Routes
    class Base < Sinatra::Application
      configure do
        set :show_exceptions, :after_handler

        Errors::ApiError.setup_i18n(Dir[File.expand_path('../../vendor/errors/i18n/*.yml', __FILE__)], :en)
      end

      before do
        logger.info('request.started', path: request.path, method: request.request_method)
      end

      after do
        logger.info('request.ended', reponse_code: response.status)
      end

      error Errors::ApiError do |error|
        logger.error('error', description: error.message, code: error.code)
        halt error.response_code, { description: error.message, code: error.code }.to_json
      end
    end
  end
end
