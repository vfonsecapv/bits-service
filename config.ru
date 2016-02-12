require './app'
require 'puma'

set :logging, false
run Bits::App
