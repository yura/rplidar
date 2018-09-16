module Rplidar
  # Data response for one scan measurement
  class ScanDataResponse < Response
    def check_header
      unless correct_start_bit?
        raise 'Inversed start bit of the data response ' \
          'is not inverse of the start bit'
      end

      raise 'Check bit of the data response is not equal to 1' \
        unless correct_check_bit?
    end

    def correct_start_bit?
      # start bit
      start = raw_response[0][0]
      # inversed start bit
      inversed = raw_response[0][1]

      (start == 1 && inversed.zero?) || (start.zero? && inversed == 1)
    end

    def correct_check_bit?
      raw_response[1][0] == 1
    end

    def start?
      raw_response[0][0] == 1
    end

    def quality
      raw_response[0] >> 2
    end

    def angle
      ((raw_response[2] << 7) + (raw_response[1] >> 1)) / 64.0
    end

    def distance
      ((raw_response[4] << 8) + raw_response[3]) / 4.0
    end

    def response
      {
        start: start?,
        quality: quality,
        angle: angle,
        distance: distance
      }
    end
  end
end
