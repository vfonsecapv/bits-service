module Bits
 class BlobstoreFactory
    def initialize(config)
      raise 'Missing config' unless config
      raise 'Missing :buildpacks config' unless config[:buildpacks]

      @fog_connection = config[:buildpacks][:fog_connection]
      raise 'Missing :fog_connection config' unless @fog_connection

      @directory_key = config[:buildpacks][:buildpack_directory_key] || 'cc-buildpacks'
    end

    def create_buildpack_blobstore
      Blobstore::Client.new(@fog_connection, @directory_key)
    end
 end
end

