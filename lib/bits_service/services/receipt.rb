require 'pathname'
require 'find'

module BitsService
  class Receipt
    def initialize(destination_path)
      @destination_path = destination_path
    end

    def contents
      Find.find(@destination_path).select { |e| File.file?(e) }.map do |file|
        digest = Digester.new.digest_path(file)
        file_path = Pathname(file).relative_path_from(Pathname(@destination_path))
        { 'fn' => file_path.to_s, 'sha1' => digest }
      end
    end
  end
end
