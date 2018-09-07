require 'spec_helper'
require 'rplidar'
require 'rubyserial'

# do not convert string to unicode
def ascii(string)
  string.force_encoding('ASCII-8BIT')
end

# Raw response descriptors
RAW_RD_GET_HEALTH = ascii("\xA5Z\x03\x00\x00\x00\x06")
RAW_RD_SCAN       = ascii("\xA5Z\x05\x00\x00@\x81")

# Data Responses
DR_HEALTH_GOOD    = [0, 0, 0].freeze
DR_HEALTH_WARNING = [1, 0, 0].freeze
DR_HEALTH_ERROR   = [2, 3, 5].freeze

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
      allow(lidar).to receive(:response_descriptor)
        .and_return(data_response_length: 3)
      allow(lidar).to receive(:data_response)
        .with(3)
        .and_return([0, 0, 0])
    end

    it 'sends GET_HEALTH request' do
      current_state
      expect(lidar).to have_received(:request).with(0x52)
    end

    it 'reads response_descriptor' do
      current_state
      expect(lidar).to have_received(:response_descriptor)
    end

    it 'reads data_response' do
      current_state
      expect(lidar).to have_received(:data_response).with(3)
    end

    it 'returns :good if lidar is in Good (0) state' do
      allow(lidar).to receive(:data_response)
        .with(3)
        .and_return(DR_HEALTH_GOOD)
      expect(current_state).to eq([:good, []])
    end

    it 'returns :warning if lidar is in Warning (1) state' do
      allow(lidar).to receive(:data_response)
        .with(3)
        .and_return(DR_HEALTH_WARNING)
      expect(current_state).to eq([:warning, []])
    end

    it 'returns :error if lidar is in Error (2) state' do
      allow(lidar).to receive(:data_response)
        .with(3)
        .and_return(DR_HEALTH_ERROR)
      expect(current_state).to eq([:error, [3, 5]])
    end

    it 'concatenates error code bytes'
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
      allow(lidar).to receive(:request).with(0x20) # start
      allow(lidar).to receive(:request).with(0x25) # stop
      allow(lidar).to receive(:response_descriptor)
        .and_return(data_response_length: 5)
      allow(lidar).to receive(:data_response)
        .and_return([61, 73, 178, 108, 4], [62, 77, 178, 104, 4], [61, 73, 178, 108, 4])
      allow(lidar).to receive(:clear_buffer)
    end

    it 'sends SCAN request' do
      scan
      expect(lidar).to have_received(:request).with(0x20)
    end

    it 'reads SCAN response descriptor' do
      scan
      expect(lidar).to have_received(:response_descriptor)
    end

    it 'reads SCAN data response' do
    end

    it 'clears buffer' do
      scan
      expect(lidar).to have_received(:clear_buffer)
    end
  end

  describe '#stop' do
    subject(:stop) { lidar.stop }

    before do
      allow(lidar).to receive(:request).with(0x25)
      allow(lidar).to receive(:clear_buffer)
    end

    it 'sends STOP request' do
      stop
      expect(lidar).to have_received(:request).with(0x25)
    end

    it 'sleeps for at least 1 ms'

    it 'clears port afterwards' do
      stop
      expect(lidar).to have_received(:clear_buffer)
    end
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

    it 'gets serial port' do
      request
      expect(lidar).to have_received(:port)
    end

    it 'writes binary string to the serial port' do
      request
      expect(port).to have_received(:write).with(ascii("\xA5 "))
    end
  end

  describe '#response_descriptor' do
    before do
      allow(port).to receive(:read)
        .with(7)
        .and_return(RAW_RD_SCAN)
      allow(lidar).to receive(:parse_response_descriptor)
        .with(RAW_RD_SCAN)
        .and_return({})
    end

    it 'reads 7 bytes from the port' do
      lidar.response_descriptor
      expect(port).to have_received(:read).with(7)
    end

    it 'calls parse_response_descriptor' do
      lidar.response_descriptor
      expect(lidar).to have_received(:parse_response_descriptor)
        .with(RAW_RD_SCAN)
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

  describe '#scan_data_response' do
    subject(:scan_data_response) { lidar.scan_data_response(5) }

    it ''
  end

  describe '#data_response_has_correct_start_flags?' do
    it 'raises inversed start flag bit is not inverse of the start flag bit' do
      [[[1, 1]], [[0, 0]], [[1, -2]], [[0, -1]]].each do |wrong_response|
        expect do
          lidar.data_response_has_correct_start_flags?(wrong_response)
        end.to raise_error('Inversed start flag bit of the data response if not inverse of the start bit')
      end
    end

    it 'raises an exception if 3rd bit is not equal to 1' do
      [[[1, 0], [0]], [[0, 1], [2]]].each do |wrong_response|
        expect do
          lidar.data_response_has_correct_start_flags?(wrong_response)
        end.to raise_error('Check bit of the data response is not equal to 1')
      end
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
    it 'processes GET_HEALTH response descriptor correctly' do
      expect(lidar.parse_response_descriptor(RAW_RD_GET_HEALTH)).to \
        eq(data_response_length: 3, send_mode: 0, data_type: 6)
    end

    it 'processes scan response descriptor correctly' do
      expect(lidar.parse_response_descriptor(RAW_RD_SCAN)).to \
        eq(data_response_length: 5, send_mode: 1, data_type: 129)
    end
  end

  describe '#binary_to_ints' do
    it 'converts binary sequence to integer array' do
      expect(lidar.binary_to_ints(RAW_RD_GET_HEALTH)).to \
        eq([165, 90, 3, 0, 0, 0, 6])
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
