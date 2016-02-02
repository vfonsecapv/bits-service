require 'support/spec_helper'

describe 'The App' do
  it "says hello" do
    get '/hi'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World!')
  end
end
