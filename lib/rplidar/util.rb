module Rplidar
  # Binary encoding, decoding, checksum methods.
  module Util
    def checksum(string)
      binary_to_ints(string).reduce(:^)
    end

    def ints_to_binary(array, format = 'C*')
      [array].flatten.pack(format)
    end

    def binary_to_ints(string, format = 'C*')
      string.unpack(format)
    end
  end
end
