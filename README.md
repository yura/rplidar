[![Build Status](https://semaphoreci.com/api/v1/yurykotlyarov/rplidar-ruby/branches/master/shields_badge.svg)](https://semaphoreci.com/yurykotlyarov/rplidar-ruby) [![codecov](https://codecov.io/gh/yura/rplidar-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/yura/rplidar-ruby) [![Maintainability](https://api.codeclimate.com/v1/badges/3e73393095982858c97b/maintainability)](https://codeclimate.com/github/yura/rplidar/maintainability) [![security](https://hakiri.io/github/yura/rplidar-ruby/master.svg)](https://hakiri.io/github/yura/rplidar-ruby/master)

## Usage

Run `bundle exec irb`

```ruby
require './lib/rplidar'

# for Mac OS
lidar = Rplidar.new('/dev/tty.SLAB_USBtoUART')
lidar.current_state

lidar.start_motor
lidar.scan
...
lidar.stop
lidar.stop_motor
lidar.close
```
