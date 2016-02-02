module Bits
  module Blobstore
    class IdempotentDirectory
      def initialize(directory)
        @directory = directory
      end

      def get_or_create
        @directory.get || @directory.create
      end
    end
  end
end
