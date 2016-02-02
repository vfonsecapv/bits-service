$LOAD_PATH.unshift(File.expand_path('../../..', __FILE__))

require 'app'

require 'rspec'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Bits::App
end
