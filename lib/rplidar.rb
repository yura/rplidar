class Rplidar
  def scan
    request([ 0xA5, 0x20 ])
  end

  def request(params)
    port.write(ints_to_binary(params))
  end

  def port
  end

  def ints_to_binary(array)
    array.pack('v*')
  end
end
