require 'rplidar/driver'
require 'rplidar/response'
require 'rplidar/response_descriptor'
require 'rplidar/scan_data_response'
require 'rplidar/current_state_data_response'
require 'rplidar/device_info_data_response'
require 'rplidar/version'

module Rplidar
  # Lidar states
  STATE_GOOD    = 0
  STATE_WARNING = 1
  STATE_ERROR   = 2
end
