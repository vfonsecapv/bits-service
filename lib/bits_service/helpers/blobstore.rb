module BitsService
  module Helpers
    module Blobstore
      def buildpack_blobstore
        @buildpack_blobstore ||= create_client(:buildpacks)
      end

      def buildpack_cache_blobstore
        @buildpack_cache_blobstore ||= create_client(:buildpack_cache, 'buildpack_cache')
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

      def create_client(key, root_dir=nil)
        cfg = config.fetch(key)

        BitsService::Blobstore::ClientProvider.provide(
          options: cfg,
          directory_key: cfg.fetch(:directory_key, key.to_s),
          root_dir: root_dir,
        )
      end
    end
  end
end
