require 'rubygems'
require 'bundler'

Bundler.require

require 'active_support/core_ext/object/try'

Dir[File.expand_path('../app/**/*.rb', __FILE__)].each do |file|
  require file
end

module Bits
  class App < Sinatra::Application
    use Routes::Buildpacks
  end
end
