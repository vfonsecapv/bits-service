require 'yaml'

module Bits
  module Helpers
    module Config
      def config
        @config ||= YAML.load_file(ENV.fetch('BITS_CONFIG_FILE')).deep_symbolize_keys
      end

      def use_nginx?
        config[:nginx][:use_nginx]
      end
    end
  end
end
