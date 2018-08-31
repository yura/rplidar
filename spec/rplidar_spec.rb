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
  let(:port) { instance_double('serial port') }

  before do
    allow(Serial).to receive(:new).with('/serial', 115_200, 8, :none, 1) { port }
  end

  describe '#current_state' do
    subject(:current_state) { lidar.current_state }

    before do
      allow(lidar).to receive(:request).with(0x52)
      allow(lidar).to receive(:response_descriptor).and_return({})
    end

    it 'sends GET_HEALTH request' do
      current_state
      expect(lidar).to have_received(:request).with(0x52)
    end

    it 'calls response_descriptor' do
      current_state
      expect(lidar).to have_received(:response_descriptor)
    end
  end

  describe '#start_motor' do
    subject(:start_motor) { lidar.start_motor }

    before do
      allow(lidar).to receive(:request_with_payload).with(0xF0, 660)
    end

    it 'sends START_MOTOR command' do
      start_motor
      expect(lidar).to have_received(:request_with_payload).with(0xF0, 660)
    end
  end

  describe '#stop_motor' do
    subject(:stop_motor) { lidar.stop_motor }

    before do
      allow(lidar).to receive(:request_with_payload)
        .with(0xF0, 0).and_return(nil)
    end

    it 'sends STOP_MOTOR command' do
      stop_motor
      expect(lidar).to have_received(:request_with_payload).with(0xF0, 0)
    end
  end

  describe '#scan' do
    subject(:scan) { lidar.scan }

    before do
      allow(lidar).to receive(:request).with(0x20)
      allow(lidar).to receive(:response_descriptor).and_return({})
    end

    it 'sends SCAN request' do
      scan
      expect(lidar).to have_received(:request).with(0x20)
    end

    it 'reads SCAN response descriptor' do
      scan
      expect(lidar).to have_received(:response_descriptor)
    end
  end

  describe '#stop' do
    subject(:stop) { lidar.stop }

    before do
      allow(lidar).to receive(:request).with(0x25)
    end

    it 'sends STOP request' do
      stop
      expect(lidar).to have_received(:request).with(0x25)
    end

    it 'sleeps for at least 1 ms'
  end

  describe '#reset' do
    subject(:reset) { lidar.reset }

    before do
      allow(lidar).to receive(:request).with(0x40)
    end

    it 'sends RESET request' do
      reset
      expect(lidar).to have_received(:request).with(0x40)
    end

    it 'sleeps for at least 2 ms'
  end

  describe '#request' do
    subject(:request) { lidar.request(0x20) }

    before do
      allow(lidar).to receive(:port).and_return(port)
      allow(port).to receive(:write).with(ascii("\xA5 "))
    end

    it 'writes binary string to the serial port' do
      request
      expect(lidar).to have_received(:port)
      expect(port).to have_received(:write).with(ascii("\xA5 "))
    end
  end

  describe '#response_descriptor' do
    before do
      allow(port).to receive(:read)
        .with(7)
        .and_return(RESPONSE_DESCRIPTOR_SCAN)
      allow(lidar).to receive(:parse_response_descriptor)
        .with(RESPONSE_DESCRIPTOR_SCAN)
        .and_return({})
    end

    it 'reads 7 bytes from the port' do
      lidar.response_descriptor
      expect(port).to have_received(:read).with(7)
    end

    it 'calls parse_response_descriptor' do
      lidar.response_descriptor
      expect(lidar).to have_received(:parse_response_descriptor)
        .with(RESPONSE_DESCRIPTOR_SCAN)
    end
  end

  describe '#request_with_payload' do
    subject(:request_with_payload) { lidar.request_with_payload(0xF0, 660) }

    before do
      allow(port).to receive(:write).with(ascii("\xA5\xF0\x02\x94\x02\xC1"))
    end

    it 'writes binary string with payload to the serial port' do
      request_with_payload
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
    subject(:close) { lidar.close }

    before do
      allow(port).to receive(:close)
    end

    it 'does not close the port if it is not open' do
      close
      expect(port).not_to have_received(:close)
    end

    it 'closes the port if it is exist' do
      # open create port first
      lidar.port

      close
      expect(port).to have_received(:close)
    end
  end

  describe '#port' do
    it 'opens serial port' do
      lidar.port
      expect(Serial).to have_received(:new).with('/serial', 115_200, 8, :none, 1)
    end

    it 'does not open port if it is already open' do
      # call it first time
      lidar.port

      # call it second time
      lidar.port
      expect(Serial).to have_received(:new).with(any_args).once
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
    it 'coverts integer to the binary sequence' do
      expect(lidar.ints_to_binary(97)).to eq('a')
    end

    it 'converts array with one integer to the binary sequence' do
      expect(lidar.ints_to_binary([97])).to eq('a')
    end

    it 'converts array of integers to the binary sequence' do
      expect(lidar.ints_to_binary([0xA5, 0x20])).to eq(ascii("\xA5 "))
    end
  end
end
