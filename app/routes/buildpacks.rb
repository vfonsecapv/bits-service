module Bits
  module Routes
    class Buildpacks < Sinatra::Application
      get '/hi' do
        "Hello World!"
      end
    end
  end
end
