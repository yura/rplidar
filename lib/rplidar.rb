class Rplidar
  COMMAND_SCAN = 0x20
  COMMAND_STOP = 0x25

  UART_BAUD_RATE = 115200

  def initialize(port_address)
    @port_address = port_address
  end

  def scan
    request(COMMAND_SCAN)
  end

  def stop
    request(COMMAND_STOP)
  end

  def request(command)
    params = [ 0xA5, command ]
    port.write(ints_to_binary(params))
  end

  def port
    @port ||= Serial.new(@port_address, UART_BAUD_RATE)
  end

  def ints_to_binary(array)
    array.pack('v*')
  end
end
