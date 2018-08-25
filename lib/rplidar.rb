require 'rubyserial'

class Rplidar
  COMMAND_GET_HEALTH = 0x52
  COMMAND_START_MOTOR = 0xF0
  COMMAND_SCAN = 0x20
  COMMAND_STOP = 0x25

  UART_BAUD_RATE = 115200

  def initialize(port_address)
    @port_address = port_address
  end

  def get_health
    request(COMMAND_GET_HEALTH)
    descriptor = parse_response_descriptor(port.read(7))
    data_response = parse_data_response(port.read(descriptor[:data_response_length]))
  end

  def start_motor
    request_with_payload(COMMAND_START_MOTOR, 660)
  end

  def stop_motor
    request_with_payload(COMMAND_START_MOTOR, 0)
  end

  def scan
    request(COMMAND_SCAN)
  end

  def stop
    request(COMMAND_STOP)
  end

  def port
    @port ||= Serial.new(@port_address, UART_BAUD_RATE, 8, :none, 1)
  end

  def close
    if @port
      @port.close
    end
  end

  def request(command)
    params = [ 0xA5, command ]
    port.write(ints_to_binary(params))
    sleep 0.002
  end

  def request_with_payload(command, payload)
    payload_string = ints_to_binary(payload, 'S<*')
    payload_size =  payload_string.size

    string = ints_to_binary([ 0xA5, command, payload_size ])
    string += payload_string
    string += ints_to_binary(checksum(string))

    port.write(string)
  end

  def checksum(string)
    result = 0
    binary_to_ints(string).each { |c| result ^= c }
    result
  end

  # Format of Response Descriptor:
  #
  # Start Flag 1   Start Flag 2    Data Response Length  Send Mode  Data Type
  #
  # 1 byte (0xA5)  1 bytes (0x5A)  30 bits               2 bits     1 byte
  def parse_response_descriptor(string)
    response = binary_to_ints(string)

    # TODO: check response headers

    {
      data_response_length: (response[5]>>2) + (response[4]<<16) + (response[3]<<8) + response[2],
      send_mode: response[5] & 0b11,
      data_type: response[6]
    }
  end

  def parse_data_response(string)
    binary_to_ints(string)
  end

  def ints_to_binary(array, format = 'C*')
    [ array ].flatten.pack(format)
  end

  def binary_to_ints(string, format = 'C*')
    string.unpack(format)
  end
end
