module Bits
  module Environment
    class << self
      def init
        load_configuration(ENV.fetch('BITS_CONFIG_FILE'))
      rescue KeyError => e
        puts "Missing configuration file."
        puts "Please set BITS_CONFIG_FILE to point to a valid configuraiton file."
        raise e
      end

      def load_configuration(path)
        @config = YAML.load_file(path).deep_symbolize_keys
      end

      def config
        @config
      end
    end
  end
end
