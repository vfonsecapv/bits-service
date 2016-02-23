require 'bits_service/routes/upload_params'

module BitsService
  module Helpers
    module Uploads
      def upload_params
        @uploads_params ||= Routes::UploadParams.new(params, use_nginx: use_nginx?)
      end
    end
  end
end
