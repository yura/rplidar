require 'spec_helper'
require 'rplidar'
require 'rubyserial'

describe Rplidar do
  let(:lidar) { Rplidar.new('/serial') }

  describe '#scan' do
    subject { lidar.scan }

    it 'sends scan request' do
      expect(lidar).to receive(:request).with(0x20)
      subject
    end
  end

  describe '#stop' do
    subject { lidar.stop }

    it 'sends stop request' do
      expect(lidar).to receive(:request).with(0x25)
      subject
    end
  end

  describe '#request' do
    subject { lidar.request(0x20) }
    let(:port) { double('serial port') }

    it 'write binary string to the serial port' do
      expect(lidar).to receive(:port).and_return(port)
      expect(port).to receive(:write).with("\xA5\x00 \x00".force_encoding('ASCII-8BIT'))
      subject
    end
  end

  describe '#close' do
    subject { lidar.close }
    let(:port) { double('serial port') }

    it 'does not close the port if it is not open' do
      expect(port).to_not receive(:close)
      subject
    end

    it 'closes the port if it is exist' do
      allow(Serial).to receive(:new).with('/serial', 115200).and_return(port)
      lidar.port

      expect(port).to receive(:close).and_return(true)
      subject
    end
  end

  describe '#port' do
    subject { lidar.port }
    let(:port) { double('serial port') }

    before do
      allow(Serial).to receive(:new).with('/serial', 115200).and_return(port)
    end

    it 'opens serial port' do
      expect(Serial).to receive(:new).with('/serial', 115200).and_return(port)
      subject
    end

    it 'does not open port if it is already open' do
      # call it first time
      lidar.port

      expect(Serial).to_not receive(:new).with('/serial', 115200)
      # call it second time
      subject
    end
  end

  describe '#ints_to_binary' do
    it 'converts array of integers to binary sequence' do
      expect(lidar.ints_to_binary([ 97 ])).to eq("a\x00")
      expect(lidar.ints_to_binary([ 0xA5, 0x20 ])).to eq("\xA5\x00 \x00".force_encoding('ASCII-8BIT'))
    end
  end
end
