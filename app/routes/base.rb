module Bits
  module Routes
    class Base < Sinatra::Application
      configure do
        set :show_exceptions, :after_handler

        Errors::ApiError.setup_i18n(Dir[File.expand_path('../../vendor/errors/i18n/*.yml', __FILE__)], :en)
      end

      error Errors::ApiError do |error|
        halt error.response_code, {description: error.message, code: error.code}.to_json
      end
    end
  end
end
