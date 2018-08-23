require 'rubyserial'

class Rplidar
  COMMAND_GET_HEALTH = 0x52
  COMMAND_SCAN = 0x20
  COMMAND_STOP = 0x25

  UART_BAUD_RATE = 115200

  def initialize(port_address)
    @port_address = port_address
  end

  def get_health
    request(COMMAND_GET_HEALTH)
    response = port.read(7)
  end

  def scan
    request(COMMAND_SCAN)
  end

  def stop
    request(COMMAND_STOP)
  end

  def close
    if @port
      @port.close
    end
  end

  def request(command)
    params = [ 0xA5, command ]
    port.write(ints_to_binary(params))
  end

  def port
    @port ||= Serial.new(@port_address, UART_BAUD_RATE, 8, :none, 1)
  end

  def ints_to_binary(array)
    array.pack('C*')
  end
end
