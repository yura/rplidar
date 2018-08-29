require 'spec_helper'
require 'rplidar'
require 'rubyserial'

# do not convert string to unicode
def ascii(string)
  string.force_encoding('ASCII-8BIT')
end

RESPONSE_DESCRIPTOR_SCAN = ascii("\xA5Z\x05\x00\x00@\x81")

describe Rplidar do
  let(:lidar) { described_class.new('/serial') }
  let(:port) { double('serial port') }

  before do
    allow(Serial).to receive(:new).with('/serial', 115_200, 8, :none, 1) { port }
  end

  describe '#get_health' do
    subject { lidar.get_health }

    before do
      allow(lidar).to receive(:request).with(0x52)
      allow(port).to receive(:read) { ascii("\xA5Z\x03\x00\x00\x00\x06") }
    end

    it 'sends GET_HEALTH request' do
      subject
      expect(lidar).to have_received(:request).with(0x52)
    end

    it 'reads 7 response bytes' do
      subject
      expect(port).to have_received(:read).with(7)
    end
  end

  describe '#start_motor' do
    subject { lidar.start_motor }

    it 'sends START_MOTOR command' do
      subject
      expect(lidar).to have_received(:request_with_payload).with(0xF0, 660)
    end
  end

  describe '#stop_motor' do
    subject { lidar.stop_motor }

    it 'sends STOP_MOTOR command' do
      subject
      expect(lidar).to have_received(:request_with_payload).with(0xF0, 0)
    end
  end

  describe '#scan' do
    subject { lidar.scan }

    before do
      allow(lidar).to receive(:request).with(0x20)
      allow(port).to receive(:read).with(7) { RESPONSE_DESCRIPTOR_SCAN }
    end

    it 'sends SCAN request' do
      subject
      expect(lidar).to have_received(:request).with(0x20)
    end

    it 'reads SCAN response descriptor' do
      subject
      expect(port).to have_received(:read).with(7)
    end
  end

  describe '#stop' do
    subject { lidar.stop }

    it 'sends STOP request' do
      subject
      expect(lidar).to have_received(:request).with(0x25)
    end

    it 'sleeps for at least 1 ms'
  end

  describe '#reset' do
    subject { lidar.reset }

    it 'sends STOP request' do
      subject
      expect(lidar).to have_received(:request).with(0x40)
    end

    it 'sleeps for at least 2 ms'
  end

  describe '#request' do
    subject { lidar.request(0x20) }

    it 'writes binary string to the serial port' do
      subject
      expect(lidar).to have_received(:port).and_return(port)
      expect(port).to have_received(:write).with(ascii("\xA5 "))
    end
  end

  describe '#request_with_payload' do
    subject { lidar.request_with_payload(0xF0, 660) }

    it 'writes binary string with payload to the serial port' do
      subject
      expect(port).to have_received(:write).with(ascii("\xA5\xF0\x02\x94\x02\xC1"))
    end
  end

  describe '#checksum' do
    it 'XORs one byte sequence' do
      expect(lidar.checksum('a')).to eq(97)
    end

    it 'XORs few bytes' do
      expect(lidar.checksum("\xA5\xF0")).to eq(0xA5 ^ 0xF0)
    end
  end

  describe '#close' do
    subject { lidar.close }

    it 'does not close the port if it is not open' do
      subject
      expect(port).not_to have_received(:close)
    end

    it 'closes the port if it is exist' do
      lidar.port

      subject
      expect(port).to have_received(:close)
    end
  end

  describe '#port' do
    subject { lidar.port }

    it 'opens serial port' do
      subject
      expect(Serial).to have_received(:new).with('/serial', 115_200, 8, :none, 1)
    end

    it 'does not open port if it is already open' do
      # call it first time
      lidar.port

      # call it second time
      subject
      expect(Serial).not_to have_received(:new).with(any_args)
    end
  end

  describe '#parse_response_descriptor' do
    it 'returns hash with parsed values' do
      expect(lidar.parse_response_descriptor(ascii("\xA5Z\x03\x00\x00\x00\x06"))).to eq(data_response_length: 3, send_mode: 0, data_type: 6)
      expect(lidar.parse_response_descriptor(ascii("\xA5Z\x05\x00\x00@\x81"))).to eq(data_response_length: 5, send_mode: 1, data_type: 129)
    end
  end

  describe '#binary_to_ints' do
    it 'converts binary sequence to integer array' do
      expect(lidar.binary_to_ints(ascii("\xA5Z\x03\x00\x00\x00\x06"))).to eq([165, 90, 3, 0, 0, 0, 6])
    end
  end

  describe '#ints_to_binary' do
    it 'converts integer or array of integers to the binary sequence' do
      expect(lidar.ints_to_binary(97)).to eq('a')
      expect(lidar.ints_to_binary([97])).to eq('a')
      expect(lidar.ints_to_binary([0xA5, 0x20])).to eq(ascii("\xA5 "))
    end
  end
end
