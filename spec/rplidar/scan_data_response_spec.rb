RSpec.describe Rplidar::ScanDataResponse do
  let(:raw_response) { [62, 155, 2, 112, 4] }
  let(:response) { described_class.new(raw_response) }

  describe '.new' do
    it 'checks header' do
      allow_any_instance_of(described_class).to receive(:check_header)
      response
      expect(response).to have_received(:check_header)
    end
  end

  describe '#check_header' do
    subject(:check_header) { response.check_header }

    before do
      allow(response).to receive(:correct_start_bit?).and_return(true)
      allow(response).to receive(:correct_check_bit?).and_return(true)
    end

    it 'does not raise any exception if header bits are correct' do
      expect { check_header }.not_to raise_error
    end

    it 'raises inversed start flag bit is not inverse of the start flag bit' do
      allow(response).to receive(:correct_start_bit?).and_return(false)

      expect { check_header }.to \
        raise_error('Inversed start bit of the data response ' \
          'is not inverse of the start bit')
    end

    it 'raises an exception if 3rd bit is not equal to 1' do
      allow(response).to receive(:correct_check_bit?).and_return(false)

      expect { response.check_header }.to \
        raise_error('Check bit of the data response is not equal to 1')
    end
  end

  describe '#correct_start_bit?' do
    it 'returns true if 1st bit of 1st byte is 1 and 2nd bit is 0' do
      allow(response).to receive(:raw_response).and_return([0b01])
      expect(response).to be_correct_start_bit
    end

    it 'returns true if 1st bit of 1st byte is 0 and 2nd bit is 1' do
      allow(response).to receive(:raw_response).and_return([0b110])
      expect(response).to be_correct_start_bit
    end

    it 'returns false if both 1st bit and 2nd one of the 1st byte are 1s' do
      allow(response).to receive(:raw_response).and_return([0b1011])
      expect(response).not_to be_correct_start_bit
    end

    it 'returns false if both 1st bit and 2nd one of the 1st byte are 0s' do
      allow(response).to receive(:raw_response).and_return([0b10100])
      expect(response).not_to be_correct_start_bit
    end
  end

  describe '#correct_check_bit?' do
    it 'returns true if 1st bit of the 2nd byte is equal to 1' do
      allow(response).to receive(:raw_response).and_return([0b10101, 0b101])
      expect(response).to be_correct_check_bit
    end

    it 'returns false if 1st bit of the 2nd byte is not equal to 1' do
      allow(response).to receive(:raw_response).and_return([0b10101, 0b10])
      expect(response).not_to be_correct_check_bit
    end
  end

  describe '#start?' do
    it 'returns false if 1st bit of the 1st byte is equal to 0' do
      expect(response).not_to be_start
    end

    it 'returns true if 1st bit of the 1st byte is equal to 1' do
      allow(response).to receive(:raw_response).and_return([0b1011])
      expect(response).to be_start
    end
  end

  describe '#angle' do
    it 'processes angle from the 2nd and 3rd bytes' do
      expect(response.angle).to eq(5.203125)
    end
  end

  describe '#distance' do
    it 'processes angle from the 4th and 5th bytes' do
      expect(response.distance).to eq(284)
    end
  end

  describe '#quality' do
    it 'processes quantity from the 1st bit' do
      expect(response.quality).to eq(15)
    end
  end

  describe '#response' do
    it 'returns a hash with response' do
      expect(response.response).to eq(
        start: false, angle: 5.203125, distance: 284, quality: 15
      )
    end
  end
end
