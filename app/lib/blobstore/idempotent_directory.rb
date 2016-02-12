module Bits
  module Blobstore
    class IdempotentDirectory
      def initialize(directory)
        @directory = directory
      end

      def fetch!
        @directory.get || @directory.create
      end
    end
  end
end
