require 'spec_helper'

RSpec.describe Rplidar::Response do
  let(:response) { described_class.new([1, 2, 3, 4, 5]) }

  describe '.new' do
    before do
      allow_any_instance_of(described_class).to receive(:check_response)
    end

    it 'creates new instance of Rplidar::Response' do
      expect(response.raw_response).to eq([1, 2, 3, 4, 5])
    end

    it 'checks response' do
      expect(response).to have_received(:check_response)
    end
  end

  describe '#check_response' do
    subject(:check_response) { response.check_response }

    before do
      allow(response).to receive(:check_header)
      allow(response).to receive(:check_payload)
    end

    it 'calls #check_header' do
      check_response
      expect(response).to have_received(:check_header)
    end

    it 'calls #check_payload' do
      check_response
      expect(response).to have_received(:check_payload)
    end
  end
end
