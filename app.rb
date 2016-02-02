require 'rubygems'
require 'bundler'

Bundler.require

Dir[File.expand_path('../app/**/*.rb', __FILE__)].each do |file|
  require file
end

module Bits
  class App < Sinatra::Application
    use Routes::Buildpacks
  end
end
