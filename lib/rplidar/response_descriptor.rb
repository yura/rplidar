module Rplidar
  # Incapsulates Response Descriptor processing. Format of Response Descriptor:
  #
  # Start Flag 1   Start Flag 2    Data Response Length  Send Mode  Data Type
  # 1 byte (0xA5)  1 bytes (0x5A)  30 bits               2 bits     1 byte
  class ResponseDescriptor < Response
    def check_response
      check_header
      check_payload
    end

    def check_header
      unless correct_first_byte?
        raise 'Wrong first byte of the response descriptor: ' \
          "'#{int_to_hex(raw_response[0])}'"
      end

      unless correct_second_byte?
        raise 'Wrong second byte of the response descriptor: ' \
          "'#{int_to_hex(raw_response[1])}'"
      end
    end

    def check_payload
      unless correct_send_mode?
        raise 'Wrong send mode value of the response descriptor: ' \
          "'#{int_to_hex(send_mode)}'"
      end

      unless correct_data_type?
        raise 'Wrong data type value of the response descriptor: ' \
          "'#{int_to_hex(data_type)}'"
      end
    end

    def correct_first_byte?
      raw_response[0] == 0xA5
    end

    def correct_second_byte?
      raw_response[1] == 0x5A
    end

    def correct_send_mode?
      [0x0, 0x1].include?(send_mode)
    end

    def correct_data_type?
      [0x6, 0x81].include?(data_type)
    end

    def data_response_length
      (raw_response[4] << 16) + (raw_response[3] << 8) + raw_response[2]
    end

    # The 2 bits Send Mode field describes the request/response mode
    # of the current session. Values:
    # * 0x0 - Single Request - Single Response mode, RPLIDAR will send
    #         only one data response packet in the current session.
    # * 0x1 - Single Request - Multiple Response mode, RPLIDAR will
    #         continuously send out data response packets with the same format
    #         in the current session.
    # * 0x2 and 0x3 are reserved for future use
    def send_mode
      raw_response[5] >> 6
    end

    # The 1byte Data Type describes the type of the incoming
    # data response packets.
    def data_type
      raw_response[6]
    end

    def response
      {
        data_response_length: data_response_length,
        send_mode: send_mode,
        data_type: data_type
      }
    end

    private

    def int_to_hex(value)
      if value
        "0x#{value.to_s(16).upcase}"
      else
        value.inspect
      end
    end
  end
end
