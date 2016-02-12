require 'rubygems'
require 'bundler'

Bundler.require

require 'active_support/core_ext/object/try'
require 'active_support/core_ext/hash/keys'

Dir[File.expand_path('../app/**/*.rb', __FILE__)].each do |file|
  require file
end

require_relative 'config/environment'

Bits::Environment.init
helpers Bits::Helpers::Config

set :dump_errors, false if ENV['RACK_ENV'] == 'production'

module Bits
  class App < Sinatra::Application
    use Routes::Buildpacks
  end
end
