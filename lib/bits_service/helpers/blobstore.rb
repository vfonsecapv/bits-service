module BitsService
  module Helpers
    module Blobstore
      def buildpack_blobstore
        @buildpack_blobstore ||= create_client(:buildpacks)
      end

      def droplet_blobstore
        @droplet_blobstore ||= create_client(:droplets)
      end

      def app_stash_blobstore
        @app_stash_blobstore ||= create_client(:app_stash)
      end

      def packages_blobstore
        @packages_blobstore ||= create_client(:packages)
      end

      private

      def create_client(key)
        cfg = config.fetch(key)

        BitsService::Blobstore::Client.new(
          cfg.fetch(:fog_connection),
          cfg.fetch(:directory_key, key.to_s),
        )
      end
    end
  end
end
