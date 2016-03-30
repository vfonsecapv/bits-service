require 'spec_helper'

module BitsService
  describe SafeZipper do
    around do |example|
      Dir.mktmpdir('foo') do |tmpdir|
        @tmpdir = tmpdir
        example.call
      end
    end

    def fixture_path(name)
      File.expand_path("../../fixtures/safe_zipper/#{name}", File.dirname(__FILE__))
    end

    describe '.unzip!' do
      let(:zip_path) { fixture_path('good.zip') }
      let(:zip_destination) { @tmpdir }

      subject(:unzip) { SafeZipper.unzip!(zip_path, zip_destination) }

      it 'unzips the file given' do
        unzip
        expect(Dir["#{zip_destination}/**/*"].size).to eq 4
        expect(Dir["#{zip_destination}/*"].size).to eq 3
        expect(Dir["#{zip_destination}/subdir/*"].size).to eq 1
      end

      it 'returns the size of the unzipped files' do
        expect(SafeZipper.unzip!(zip_path, zip_destination)).to eq 17
      end

      it 'returns the size if it is large' do
        allow(Open3).to receive(:capture3).with(%(unzip -l #{zip_path})).and_return(
          [
            "Archive:\n Filename\n ---\n 0  09-15-15 17:44 foo\n ---\n10000000001 1 file\n",
            nil,
            double('status', success?: true)]
        )
        expect(SafeZipper.unzip!(zip_path, zip_destination)).to eq 10_000_000_001
      end

      context "when the zip_destination doesn't exist" do
        let(:zip_destination) { 'bar' }

        it 'raises an exception' do
          expect { unzip }.to raise_exception SafeZipper::Error, /destination does not exist/i
        end
      end

      context 'when the underlying unzip fails' do
        let(:zip_path) { fixture_path('missing.zip') }

        it 'raises an exception' do
          expect { unzip }.to raise_exception SafeZipper::Error, /unzipping had errors\n STDOUT: ""\n STDERR: "unzip:\s+cannot find or open/im
        end
      end

      context 'when the zip is empty' do
        let(:zip_path) { fixture_path('empty.zip') }

        it 'raises an exception' do
          expect { unzip }.to raise_exception SafeZipper::Error, /unzipping had errors/i
        end
      end

      describe 'symlinks' do
        context 'when they are inside the root directory' do
          let(:zip_path) { fixture_path('good_symlinks.zip') }

          it 'unzips them archive correctly without errors' do
            unzip
            expect(File.symlink?("#{zip_destination}/what")).to be true
          end
        end

        context 'when the are outside the root directory' do
          let(:zip_path) { fixture_path('bad_symlinks.zip') }

          it 'raises an exception' do
            expect { unzip }.to raise_exception SafeZipper::Error, /symlink.+outside/i
          end
        end
      end

      describe 'relative paths' do
        context 'when the are inside the root directory' do
          let(:zip_path) { fixture_path('good_relative_paths.zip') }

          it 'unzips them archive correctly without errors' do
            unzip
            expect(File.exist?("#{zip_destination}/bar/../cat")).to be true
          end
        end

        context 'when the are outside the root directory' do
          let(:zip_path) { fixture_path('bad_relative_paths.zip') }

          it 'raises an exception' do
            expect { unzip }.to raise_exception SafeZipper::Error, /relative path.+outside/i
          end
        end

        context 'when the are outside the root directory and have spaces' do
          let(:zip_path) { fixture_path('bad_relative_paths_with_spaces.zip') }

          it 'raises an exception' do
            expect { unzip }.to raise_exception SafeZipper::Error, /relative path.+outside/i
          end
        end
      end
    end

    describe '.zip' do
      let(:root_path) { fixture_path('fake_package/') }
      let(:tmp_zip) { File.join(@tmpdir, 'tmp.zip') }

      it 'zips the file' do
        SafeZipper.zip(root_path, tmp_zip)

        output = `zipinfo #{tmp_zip}`
        expect(output).not_to include('./')
        expect(output).not_to include('fake_package')
        expect(output).to include('subdir/there')
        expect(output).to match(/^l.+coming_from_inside$/)
        expect(output).to include('4 files')
      end

      context 'when the root path is empty' do
        let(:root_path) { fixture_path('no_exist') }

        it 'will raise an error' do
          expect do
            SafeZipper.zip(root_path, tmp_zip)
          end.to raise_exception SafeZipper::Error, /path does not exist/i
        end
      end

      context 'when the destination directory does not exist' do
        let(:tmp_zip) { '/non/existent/path/to/tmp.zip' }

        it 'will raise an error' do
          expect do
            SafeZipper.zip(root_path, tmp_zip)
          end.to raise_exception SafeZipper::Error, /path does not exist/i
        end
      end

      context 'when the zipping fails' do
        let(:tmp_zip) { '/non/existent/path/to/tmp.zip' }

        it 'will raise an error' do
          allow(File).to receive(:exist?).and_return(true)

          expect do
            SafeZipper.zip(root_path, tmp_zip)
          end.to raise_exception SafeZipper::Error, /could not zip the package\n STDOUT: "zip .+?"\n STDERR: ""/im
        end
      end
    end
  end
end
