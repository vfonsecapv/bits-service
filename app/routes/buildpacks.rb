module Bits
  module Routes
    class Buildpacks < Sinatra::Application
      put '/buildpacks/:guid' do
        status 201
      end
    end
  end
end
