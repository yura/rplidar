DR_GET_INFO = [
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
].freeze

DR_GET_INFO_REAL = [
  40, 24, 1, 4, 168, 226, 154, 240, 197, 226,
  157, 210, 182, 227, 157, 245, 43, 49, 49, 22
].freeze

RSpec.describe Rplidar::DeviceInfoDataResponse do
  let(:response) { described_class.new(DR_GET_INFO) }

  describe '#model' do
    it 'returns model' do
      expect(response.model).to eq(1)
    end
  end

  describe '#firmware_minor' do
    it 'returns firmware minor' do
      expect(response.firmware_minor).to eq(2)
    end
  end

  describe '#firmware_major' do
    it 'returns firmware major' do
      expect(response.firmware_major).to eq(3)
    end
  end

  describe '#firmware' do
    it 'returns firmware version' do
      expect(response.firmware).to eq('3.2')
    end
  end

  describe '#hardware' do
    it 'returns hardware' do
      expect(response.hardware).to eq(4)
    end
  end

  describe '#serial_number' do
    it 'returns serial_number' do
      expect(response.serial_number).to eq('05060708090A0B0C0D0E0F1011121314')
    end
  end

  describe '#response' do
    it 'returns device info' do
      expect(response.response).to eq(
        model: 1, firmware: '3.2',
        hardware: 4, serial_number: '05060708090A0B0C0D0E0F1011121314'
      )
    end

    it 'returns real device info' do
      allow(response).to receive(:raw_response).and_return(DR_GET_INFO_REAL)
      expect(response.response).to eq(
        model: 40, firmware: '1.24',
        hardware: 4, serial_number: 'A8E29AF0C5E29DD2B6E39DF52B313116'
      )
    end
  end
end
