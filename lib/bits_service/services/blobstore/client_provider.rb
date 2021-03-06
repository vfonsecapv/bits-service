require 'bits_service/services/blobstore/client'
require 'bits_service/services/blobstore/fog/fog_client'
require 'bits_service/services/blobstore/webdav/dav_client'
require 'bits_service/services/blobstore/safe_delete_client'

module BitsService
  module Blobstore
    class ClientProvider
      def self.provide(options:, directory_key:, root_dir: nil)
        if options[:blobstore_type].blank? || (options[:blobstore_type] == 'fog')
          provide_fog(options, directory_key, root_dir)
        else
          provide_webdav(options, directory_key, root_dir)
        end
      end

      class << self
        private

        def provide_fog(options, directory_key, root_dir)
          cdn_uri = options[:cdn].try(:[], :uri)
          cdn     = BitsService::Blobstore::Cdn.make(cdn_uri)

          client = FogClient.new(
            options.fetch(:fog_connection),
            directory_key,
            cdn,
            root_dir,
            options[:minimum_size],
            options[:maximum_size]
          )

          Client.new(SafeDeleteClient.new(client, root_dir))
        end

        def provide_webdav(options, directory_key, root_dir)
          client = DavClient.new(
            options.fetch(:webdav_config),
            directory_key,
            root_dir,
            options[:minimum_size],
            options[:maximum_size]
          )

          Client.new(SafeDeleteClient.new(client, root_dir))
        end
      end
    end
  end
end
