require 'spec_helper'

RSpec.describe Rplidar::Response do
  let(:response) { described_class.new([1, 2, 3, 4, 5]) }

  before do
    allow_any_instance_of(described_class).to receive(:check_header)
  end

  describe '.new' do
    it 'creates new instance of Rplidar::Response' do
      expect(response.raw_response).to eq([1, 2, 3, 4, 5])
    end

    it 'checks response header' do
      expect(response).to have_received(:check_header)
    end
  end
end
