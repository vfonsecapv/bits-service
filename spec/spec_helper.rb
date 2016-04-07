ENV['BITS_CONFIG_FILE'] = './spec/fixtures/sample_config.yml' unless ENV.key?('BITS_CONFIG_FILE')
require_relative '../app'

require 'rspec'
require 'rspec/collection_matchers'
require 'rack/test'
require 'timecop'
require 'webmock/rspec'

require 'pry'
require 'pry-byebug'

require 'active_support/core_ext/object/inclusion'

Dir[File.expand_path('support/**/*.rb', File.dirname(__FILE__))].each { |file| require file }

RSpec.configure do |conf|
  conf.include Rack::Test::Methods

  conf.include IntegrationTestSettings, type: :integration
  conf.include IntegrationHttp, type: :integration
  conf.include IntegrationSetupHelpers, type: :integration
  conf.include IntegrationSetup, type: :integration

  conf.include ConfigFileHelpers
  conf.include FileHelpers

  conf.before :each do
    Fog::Mock.reset
  end

  conf.after :each do
    Timecop.return
  end
end

def app
  BitsService::App
end
