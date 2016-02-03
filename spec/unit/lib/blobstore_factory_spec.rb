require 'spec_helper'

module Bits
  describe BlobstoreFactory do
    describe '#initialze' do
      context 'when config is nil' do
        let(:config) { nil }

        it 'throws an exception' do
          expect{BlobstoreFactory.new(config)}.to raise_error 'Missing config'
        end
      end

      context 'when config is missing the :buildpacks key' do
        let(:config) { Hash.new }

        it 'throws an exception' do
          expect{BlobstoreFactory.new(config)}.to raise_error 'Missing :buildpacks config'
        end
      end

      context 'when config is missing the :fog_connection key' do
        let(:config) { {buildpacks: {}} }

        it 'throws an exception' do
          expect{BlobstoreFactory.new(config)}.to raise_error 'Missing :fog_connection config'
        end
      end
    end

    describe '#create_buildpack_blobstore' do
      let(:config) { {
        :buildpacks => {
          :fog_connection => 'fog_connection',
          :buildpack_directory_key => 'directory_key'
        }
      } }

      subject { BlobstoreFactory.new(config) }

      it 'returns a blobstore client' do
        expect(subject.create_buildpack_blobstore).to be_a(Blobstore::Client)
      end

      it 'creates a blobstore client with the correct config' do
        expect(Blobstore::Client).to receive(:new).with('fog_connection', 'directory_key')
        subject.create_buildpack_blobstore
      end

      context 'when :buildpack_directory_key is not present in config' do
        let(:config) { {
          :buildpacks => {
            :fog_connection => 'fog_connection'
          }
        } }

        it 'creates a blobstore client with the correct default directory key' do
          expect(Blobstore::Client).to receive(:new).with('fog_connection', 'cc-buildpacks')
          subject.create_buildpack_blobstore
        end
      end
    end
  end
end
