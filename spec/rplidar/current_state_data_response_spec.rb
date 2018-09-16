# Data Responses
DR_HEALTH_GOOD = [0, 0, 0].freeze
DR_HEALTH_WARN = [1, 0, 0].freeze
DR_HEALTH_ERR  = [2, 3, 5].freeze

RSpec.describe Rplidar::CurrentStateDataResponse do
  let(:data_response) { described_class.new([0, 0, 0]) }

  describe '#response' do
    subject(:response) { data_response.response }

    it 'returns :good if lidar is in Good (0) state' do
      allow(data_response).to receive(:raw_response).and_return(DR_HEALTH_GOOD)
      expect(response).to eq([:good, []])
    end

    it 'returns :warning if lidar is in Warning (1) state' do
      allow(data_response).to receive(:raw_response).and_return(DR_HEALTH_WARN)
      expect(response).to eq([:warning, []])
    end

    it 'returns :error if lidar is in Error (2) state' do
      allow(data_response).to receive(:raw_response).and_return(DR_HEALTH_ERR)
      expect(response).to eq([:error, [3, 5]])
    end

    it 'concatenates error code bytes'
  end
end
