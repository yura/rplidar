RD_GET_HEALTH     = [165, 90, 3, 0, 0, 0, 6].freeze
RD_SCAN           = [165, 90, 5, 0, 0, 64, 129].freeze

RSpec.describe Rplidar::ResponseDescriptor do
  let(:descriptor) { described_class.new(RD_SCAN) }

  describe '#check_header' do
    subject(:check_header) { descriptor.check_header }

    it 'raises "Wrong first byte of the response descriptor" exception' do
      allow(descriptor).to receive(:raw_response).and_return([90, 0, 0, 0, 0])
      expect { check_header }.to \
        raise_error("Wrong first byte of the response descriptor: '0x5A'")
    end

    it 'raises exception for nils' do
      allow(descriptor).to receive(:raw_response).and_return([nil, nil, nil])
      expect { check_header }.to \
        raise_error("Wrong first byte of the response descriptor: 'nil'")
    end

    it 'raises "Wrong second byte of the response descriptor" exception' do
      allow(descriptor).to receive(:raw_response).and_return([165, 165, 0, 0])
      expect { check_header }.to \
        raise_error("Wrong second byte of the response descriptor: '0xA5'")
    end
  end

  describe '#check_payload' do
    subject(:check_payload) { descriptor.check_payload }

    it 'raises "Wrong send mode value of the response descriptor" exception' do
      allow(descriptor).to \
        receive(:raw_response).and_return([165, 90, 3, 0, 0, 128])
      expect { check_payload }.to \
        raise_error("Wrong send mode value of the response descriptor: '0x2'")
    end

    it 'raises "Wrong data type value of the response descriptor" exception' do
      allow(descriptor).to \
        receive(:raw_response).and_return([165, 90, 3, 0, 0, 64, 1])
      expect { check_payload }.to \
        raise_error("Wrong data type value of the response descriptor: '0x1'")
    end
  end

  describe '#data_response_length' do
    subject(:data_response_length) { descriptor.data_response_length }

    it 'returns data response length for GET_HEALTH request' do
      allow(descriptor).to \
        receive(:raw_response).and_return(RD_GET_HEALTH)
      expect(data_response_length).to eq(3)
    end

    it 'returns data response length for SCAN request' do
      allow(descriptor).to \
        receive(:raw_response).and_return(RD_SCAN)
      expect(data_response_length).to eq(5)
    end
  end

  describe '#send_mode' do
    subject(:send_mode) { descriptor.send_mode }

    it 'returns Single Request - Single Response for GET_HEALTH request' do
      allow(descriptor).to receive(:raw_response).and_return(RD_GET_HEALTH)
      expect(send_mode).to eq(0x0)
    end

    it 'returns Single Request - Multiple Response for SCAN request' do
      allow(descriptor).to receive(:raw_response).and_return(RD_SCAN)
      expect(send_mode).to eq(0x1)
    end
  end

  describe '#response' do
    subject(:response) { descriptor.response }

    it 'returns processed values for SCAN request' do
      expect(response).to eq(
        data_response_length: 5,
        send_mode: 1,
        data_type: 0x81
      )
    end
  end
end
