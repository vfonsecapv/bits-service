$LOAD_PATH.unshift(File.join(__dir__, '../app'))

require 'hi'

require 'rspec'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe 'The App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "says hello" do
    get '/hi'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World!')
  end
end
