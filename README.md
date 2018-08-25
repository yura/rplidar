[![Build Status](https://semaphoreci.com/api/v1/yurykotlyarov/rplidar-ruby/branches/master/shields_badge.svg)](https://semaphoreci.com/yurykotlyarov/rplidar-ruby) [![codecov](https://codecov.io/gh/yura/rplidar-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/yura/rplidar-ruby) [![Maintainability](https://api.codeclimate.com/v1/badges/e0a84f30bd9de18c91a0/maintainability)](https://codeclimate.com/github/yura/rplidar-ruby/maintainability)

## Usage

Run `bundle exec irb`

```ruby
require './lib/rplidar'

# for Mac OS
lidar = Rplidar.new('/dev/tty.SLAB_USBtoUART')
lidar.get_health

lidar.start_motor
lidar.scan
...
lidar.stop
lidar.stop_motor
lidar.close
```
