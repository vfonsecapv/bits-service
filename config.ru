require './app'
require 'puma'

set :logging, false
run BitsService::App
