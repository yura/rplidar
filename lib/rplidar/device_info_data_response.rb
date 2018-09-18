module Rplidar
  class DeviceInfoDataResponse < Response
    # RPLIDAR model ID.
    def model
      raw_response[0]
    end

    # Firmware version number, the minor value part.
    def firmware_minor
      raw_response[1]
    end

    # Firmware version number, the major value part.
    def firmware_major
      raw_response[2]
    end

    def firmware
      "#{firmware_major}.#{firmware_minor}"
    end

    # Hardware version number.
    def hardware
      raw_response[3]
    end

    # 128bit unique serial number. When converting to text in hex,
    # the Least Significant Byte prints first.
    def serial_number
      raw_response[4..-1].pack('c*').unpack('H*').first.upcase
    end

    def response
      {
        model: model, firmware: firmware,
        hardware: hardware, serial_number: serial_number
      }
    end
  end
end
