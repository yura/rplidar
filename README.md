# Rplidar

[![Build Status](https://semaphoreci.com/api/v1/yurykotlyarov/rplidar/branches/master/shields_badge.svg)](https://semaphoreci.com/yurykotlyarov/rplidar) [![codecov](https://codecov.io/gh/yura/rplidar/branch/master/graph/badge.svg)](https://codecov.io/gh/yura/rplidar) [![Maintainability](https://api.codeclimate.com/v1/badges/3e73393095982858c97b/maintainability)](https://codeclimate.com/github/yura/rplidar/maintainability) [![security](https://hakiri.io/github/yura/rplidar/master.svg)](https://hakiri.io/github/yura/rplidar/master) [![Gem Version](https://badge.fury.io/rb/rplidar.svg)](https://badge.fury.io/rb/rplidar)

Ruby implementation of SLAMTEK RPLIDAR A2M8 lidar.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rplidar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rplidar

## Usage

Run `bundle exec irb`

```ruby
require 'rplidar'

# for Mac OS
lidar = Rplidar::Driver.new('/dev/tty.SLAB_USBtoUART')
lidar.current_state

lidar.start_motor
lidar.scan
...
lidar.stop
lidar.stop_motor
lidar.close
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yura/rplidar. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

