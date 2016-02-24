module BitsService
  module Helpers
    module Blobstore
      def buildpack_blobstore
        @buildpack_blobstore ||= BitsService::Blobstore::Client.new(
          buildpack_config.fetch(:fog_connection),
          buildpack_config.fetch(:directory_key, 'buildpacks'),
        )
      end

      private

      def buildpack_config
        config.fetch(:buildpacks)
      end
    end
  end
end
