require 'yaml'

module BitsService
  module Helpers
    module Config
      def config
        BitsService::Environment.config
      end

      def logger
        BitsService::Environment.logger
      end

      def use_nginx?
        config[:nginx][:use_nginx]
      end
    end
  end
end
