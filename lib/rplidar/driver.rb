require 'rubyserial'

module Rplidar
  # Ruby implementation of driver of the SLAMTEC RPLIDAR A2.
  class Driver
    # Commands
    COMMAND_GET_HEALTH  = 0x52
    COMMAND_GET_INFO  =   0x50
    COMMAND_MOTOR_PWM   = 0xF0
    COMMAND_SCAN        = 0x20
    COMMAND_STOP        = 0x25
    COMMAND_RESET       = 0x40

    COMMANDS_WITH_RESPONSE = [
      COMMAND_GET_HEALTH,
      COMMAND_GET_INFO,
      COMMAND_SCAN
    ].freeze

    # Default length of responses
    RESPONSE_DESCRIPTOR_LENGTH = 7
    GET_INFO_RESPONSE_LENGTH   = 20
    SCAN_DATA_RESPONSE_LENGTH  = 5

    UART_BAUD_RATE = 115_200

    def initialize(port_address)
      @port_address = port_address
    end

    def current_state
      descriptor = command(COMMAND_GET_HEALTH)
      raw_response = read_response(descriptor[:data_response_length])
      Rplidar::CurrentStateDataResponse.new(raw_response).response
    end

    def device_info
      descriptor = command(COMMAND_GET_INFO)
      raw_response = read_response(descriptor[:data_response_length])
      Rplidar::DeviceInfoDataResponse.new(raw_response).response
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
      while iteration < iterations
        response = scan_data_response
        iteration += 1 if response[:start]
        responses << response if iteration.between?(0, iterations - 1)
      end
      responses
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

    def response_descriptor
      raw_response = read_response(RESPONSE_DESCRIPTOR_LENGTH)
      Rplidar::ResponseDescriptor.new(raw_response).response
    end

    def scan_data_response
      raw_response = read_response(SCAN_DATA_RESPONSE_LENGTH)
      Rplidar::ScanDataResponse.new(raw_response).response
    end

    def read_response(length)
      t = Time.now
      response = []
      while response.size < length
        byte = port.getbyte
        response << byte if byte
        raise 'Timeout while reading a byte from the port' if Time.now - t > 2
      end
      response
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
end
