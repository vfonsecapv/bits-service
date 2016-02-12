require 'yaml'

module Bits
  module Helpers
    module Config
      def config
        Bits::Environment.config
      end

      def use_nginx?
        config[:nginx][:use_nginx]
      end
    end
  end
end
