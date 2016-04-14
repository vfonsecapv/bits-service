require 'spec_helper'

module BitsService
  describe Receipt do
    let(:destination_path) { '/tmp/path/' }
    subject { Receipt.new(destination_path) }

    let(:folder_contents) do
      ['/tmp/path/app.rb', '/tmp/path/lib/lib.rb', '/tmp/path/.git', '/tmp/path/.git/content']
    end

    before do
      allow(Find).to receive(:find).with(destination_path).and_return(folder_contents)
      allow(File).to receive(:file?).with('/tmp/path/app.rb').and_return(true)
      allow(File).to receive(:file?).with('/tmp/path/lib/lib.rb').and_return(true)
      allow(File).to receive(:file?).with('/tmp/path/.git').and_return(false)
      allow(File).to receive(:file?).with('/tmp/path/.git/content').and_return(true)

      allow_any_instance_of(Digester).to receive(:digest_path).with('/tmp/path/app.rb').and_return('123')
      allow(File).to receive(:stat).with('/tmp/path/app.rb').and_return(double(:stat, mode: 33279))
      allow_any_instance_of(Digester).to receive(:digest_path).with('/tmp/path/lib/lib.rb').and_return('345')
      allow(File).to receive(:stat).with('/tmp/path/lib/lib.rb').and_return(double(:stat, mode: 33206))
      allow_any_instance_of(Digester).to receive(:digest_path).with('/tmp/path/.git/content').and_return('567')
      allow(File).to receive(:stat).with('/tmp/path/.git/content').and_return(double(:stat, mode: 33152))
    end

    it 'returns an hash with "fn" and "sha1" for all the entries in the folder' do
      receipt = subject.contents
      expect(receipt).to include({ 'fn' => 'app.rb', 'sha1' => '123', 'mode' => '777' })
      expect(receipt).to include({ 'fn' => 'lib/lib.rb', 'sha1' => '345', 'mode' => '666' })
      expect(receipt).to include({ 'fn' => '.git/content', 'sha1' => '567', 'mode' => '600' })
    end

    context 'when the destination path does not exist' do
      before do
        allow(Find).to receive(:find).with(destination_path).and_raise(Errno::ENOENT)
      end

      it 'raises an exception' do
        expect { subject.contents }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when the destination path is empty' do
      let(:folder_contents) { [] }

      it 'returns an empty list' do
        receipt = subject.contents
        expect(receipt).to be_empty
      end
    end
  end
end
