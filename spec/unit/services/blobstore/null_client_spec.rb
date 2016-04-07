require 'spec_helper'
require 'bits_service/services/blobstore/null_client'
require_relative 'client_shared'

module BitsService
  module Blobstore
    describe NullClient do
      subject(:client) { NullClient.new }
      let(:deletable_blob) { instance_double(Blob) }

      it_behaves_like 'a blobstore client'
    end
  end
end
