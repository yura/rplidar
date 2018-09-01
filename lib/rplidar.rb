require 'rubyserial'

# Ruby implementation of driver of the Rplidar A2.
class Rplidar
  # Lidar states
  STATE_GOOD = 0
  STATE_WARNING = 1
  STATE_ERROR = 2

  # Commands
  COMMAND_GET_HEALTH  = 0x52
  COMMAND_MOTOR_PWM   = 0xF0
  COMMAND_SCAN        = 0x20
  COMMAND_STOP        = 0x25
  COMMAND_RESET       = 0x40

  # Default length of response descriptors
  RESPONSE_DESCRIPTOR_SIZE = 7

  UART_BAUD_RATE = 115_200

  def initialize(port_address)
    @port_address = port_address
  end

  def current_state
    request(COMMAND_GET_HEALTH)
    descriptor = response_descriptor
    response = data_response(descriptor[:data_response_length])
    case response[0]
      when STATE_GOOD    then [:good, []]
      when STATE_WARNING then [:warning, []]
      when STATE_ERROR   then [:error, response[1..-1]]
    end
  end

  def start_motor
    request_with_payload(COMMAND_MOTOR_PWM, 660)
  end

  def stop_motor
    request_with_payload(COMMAND_MOTOR_PWM, 0)
  end

  def scan(iterations = 10)
    request(COMMAND_SCAN)
    descriptor = response_descriptor

    # i = 0
    # File.open('output.bin', 'w') do |file|
    #   loop do
    #     break if i >= iterations
    #     file.puts binary_to_ints(port.read(descriptor[:data_response_length])).inspect
    #     i += 1
    #   end
    # end
    # stop
    # stop_motor
  end

  def stop
    request(COMMAND_STOP)
  end

  def reset
    request(COMMAND_RESET)
  end

  def port
    @port ||= Serial.new(@port_address, UART_BAUD_RATE, 8, :none, 1)
  end

  def close
    @port.close if @port
  end

  def request(command)
    params = [0xA5, command]
    port.write(ints_to_binary(params))
    sleep 0.002
  end

  def request_with_payload(command, payload)
    payload_string = ints_to_binary(payload, 'S<*')
    payload_size = payload_string.size

    string = ints_to_binary([0xA5, command, payload_size])
    string += payload_string
    string += ints_to_binary(checksum(string))

    port.write(string)
  end

  def checksum(string)
    result = 0
    binary_to_ints(string).each { |c| result ^= c }
    result
  end

  def response_descriptor
    parse_response_descriptor(port.read(RESPONSE_DESCRIPTOR_SIZE))
  end

  def data_response(length)
    binary_to_ints(port.read(length))
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
      data_response_length: (response[4] << 16) + (response[3] << 8) + response[2],
      send_mode: response[5] >> 6,
      data_type: response[6]
    }
  end

  def ints_to_binary(array, format = 'C*')
    [array].flatten.pack(format)
  end

  def binary_to_ints(string, format = 'C*')
    string.unpack(format)
  end
end
