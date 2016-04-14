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
        { 'fn' => file_path.to_s, 'sha1' => digest, 'mode' => file_mode(file) }
      end
    end

    private

    def file_mode(file_path)
      (File.stat(file_path).mode.to_s(8).to_i % 1000).to_s
    end
  end
end
