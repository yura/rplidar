[![Build Status](https://semaphoreci.com/api/v1/yurykotlyarov/rplidar-ruby/branches/master/shields_badge.svg)](https://semaphoreci.com/yurykotlyarov/rplidar-ruby) [![codecov](https://codecov.io/gh/yura/rplidar-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/yura/rplidar-ruby)

## Usage

Run `bundle exec irb`

```ruby
require './lib/rplidar'

# for Mac OS
lidar = Rplidar.new('/dev/tty.SLAB_USBtoUART')
lidar.get_health

lidar.scan
...
lidar.stop
lidar.close
```

