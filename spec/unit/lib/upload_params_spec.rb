require 'spec_helper'

module Bits
  describe UploadParams do
    let(:key) { 'application' }

    describe '#original_filename' do
      subject { UploadParams.new(params) }

      context 'when the name param exists' do
        let(:params) { { "#{key}_name" => 'original_name' } }

        it 'returns the correct value' do
          expect(subject.original_filename(key)).to eq('original_name')
        end
      end

      context 'when the name param does not exist' do
        let(:params) { Hash.new }

        it 'returns nil' do
          expect(subject.original_filename(key)).to be_nil
        end
      end
    end

    describe '#upload_filepath' do

      context 'Nginx mode' do
        subject { UploadParams.new(params, use_nginx: true) }

        context 'when the path param exists' do
          let(:params) { { "#{key}_path" => 'a path' } }

          it 'returns the correct path' do
            expect(subject.upload_filepath(key)).to eq('a path')
          end
        end

        context 'when the path param does not exist' do
          let(:params) { { 'foobar_path' => 'a path' } }

          it 'returns nil' do
            expect(subject.upload_filepath(key)).to be_nil
          end
        end
      end

      context 'Rack Mode' do
        subject { UploadParams.new(params, use_nginx: false) }

        context 'when the tempfile key is a symbol' do
          let(:params) { { key => { tempfile: Struct.new(:path).new('a path') } } }

          it 'returns the uploaded file from the :tempfile synthetic variable' do
            expect(subject.upload_filepath(key)).to eq('a path')
          end
        end

        context 'when the value of the tmpfile is a string' do
          let(:params) { { key => { 'tempfile' => 'a path' } } }

          it 'returns the correct value' do
            expect(subject.upload_filepath(key)).to eq('a path')
          end
        end

        context 'when there is no corresponding param' do
          let(:params) { { key => nil } }

          it 'returns nil' do
            expect(subject.upload_filepath(key)).to be_nil
          end
        end
      end
    end
  end
end
