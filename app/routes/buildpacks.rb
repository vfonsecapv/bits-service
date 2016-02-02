module Bits
  module Routes
    class Buildpacks < Sinatra::Application
      put '/buildpacks/:guid' do
        status 201
      end

      get '/hi' do
        "Hello World!"
      end
    end
  end
end
