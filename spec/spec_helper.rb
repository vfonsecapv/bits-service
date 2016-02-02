require_relative '../app'

require 'rspec'
require 'rack/test'

Dir[File.expand_path('support/**/*.rb', File.dirname(__FILE__))].each { |file| require file }

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Bits::App
end
