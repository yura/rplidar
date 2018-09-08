require 'rubyserial'

# Ruby implementation of driver of the SLAMTEC RPLIDAR A2.
class Rplidar
  # Lidar states
  STATE_GOOD    = 0
  STATE_WARNING = 1
  STATE_ERROR   = 2

  # Commands
  COMMAND_GET_HEALTH  = 0x52
  COMMAND_MOTOR_PWM   = 0xF0
  COMMAND_SCAN        = 0x20
  COMMAND_STOP        = 0x25
  COMMAND_RESET       = 0x40

  COMMANDS_WITH_RESPONSE = [
    COMMAND_GET_HEALTH,
    COMMAND_SCAN
  ].freeze

  # Default length of responses
  RESPONSE_DESCRIPTOR_LENGTH = 7
  SCAN_DATA_RESPONSE_LENGTH  = 5

  UART_BAUD_RATE = 115_200

  def initialize(port_address)
    @port_address = port_address
  end

  def current_state
    descriptor = command(COMMAND_GET_HEALTH)
    response = data_response(descriptor[:data_response_length])
    case response[0]
    when STATE_GOOD    then [:good, []]
    when STATE_WARNING then [:warning, []]
    when STATE_ERROR   then [:error, response[1..-1]]
    end
  end

  def start_motor(pwm = 660)
    request_with_payload(COMMAND_MOTOR_PWM, pwm)
  end

  def stop_motor
    request_with_payload(COMMAND_MOTOR_PWM, 0)
  end

  def scan_to_file(filename = 'output.csv', iterations = 1)
    responses = scan(iterations)

    File.open(filename, 'w') do |file|
      file.puts 'start,quality,angle,distance'
      responses.each do |r|
        file.puts "#{r[:start]},#{r[:quality]},#{r[:angle]},#{r[:distance]}"
      end
    end
  end

  def scan(iterations = 1)
    command(COMMAND_SCAN)
    responses = collect_scan_data_responses(iterations)
    stop

    responses
  end

  def collect_scan_data_responses(iterations)
    responses = []
    iteration = -1
    loop do
      response = scan_data_response

      responses << response if responses.empty? && response[:start] == 1

      if response[:start] == 1
        iteration += 1
        break if iteration >= iterations
      end
    end
  end

  def stop
    command(COMMAND_STOP)
    clear_port
  end

  def reset
    command(COMMAND_RESET)
  end

  def port
    @port ||= Serial.new(@port_address, UART_BAUD_RATE, 8, :none, 1)
  end

  def close
    @port.close if @port
  end

  def command(command)
    request(command)
    response_descriptor if COMMANDS_WITH_RESPONSE.include?(command)
  end

  def request(command)
    params = [0xA5, command]
    port.write(ints_to_binary(params))
    sleep 0.5
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
    binary_to_ints(string).reduce(:^)
  end

  # Format of Response Descriptor:
  #
  # Start Flag 1   Start Flag 2    Data Response Length  Send Mode  Data Type
  #
  # 1 byte (0xA5)  1 bytes (0x5A)  30 bits               2 bits     1 byte
  def response_descriptor
    response = data_response(RESPONSE_DESCRIPTOR_LENGTH)

    # TODO: check response headers

    {
      data_response_length: (response[4] << 16) +
        (response[3] << 8) + response[2],
      send_mode: response[5] >> 6,
      data_type: response[6]
    }
  end

  def data_response(length)
    response = []
    while response.size < length
      byte = port.getbyte
      response << byte if byte
    end
    response
  end

  def scan_data_response
    response = data_response(SCAN_DATA_RESPONSE_LENGTH)
    check_data_response_header(response)

    {
      start: response[0][0],
      quality: quality(response),
      angle: angle(response),
      distance: distance(response)
    }
  end

  def check_data_response_header(response)
    raise 'Inversed start bit of the data response is not inverse of the start bit' unless correct_start_bit?(response)
    raise 'Check bit of the data response is not equal to 1' unless correct_check_bit?(response)
  end

  def correct_start_bit?(response)
    # start bit
    start = response[0][0]
    # inversed start bit
    inversed = response[0][1]

    (start == 1 && inversed.zero?) || (start.zero? && inversed == 1)
  end

  def correct_check_bit?(response)
    response[1][0] == 1
  end

  def quality(response)
    response[0] >> 2
  end

  def angle(response)
    ((response[2] << 7) + (response[1] >> 1)) / 64.0
  end

  def distance(response)
    ((response[4] << 8) + response[3]) / 4.0
  end

  def clear_port
    while port.getbyte
    end
  end

  def ints_to_binary(array, format = 'C*')
    [array].flatten.pack(format)
  end

  def binary_to_ints(string, format = 'C*')
    string.unpack(format)
  end
end
