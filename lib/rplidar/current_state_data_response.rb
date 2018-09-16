module Rplidar
  # Implementation of response to the GET_HEALTH request.
  class CurrentStateDataResponse < Response
    def response
      case raw_response[0]
      when STATE_GOOD    then [:good, []]
      when STATE_WARNING then [:warning, []]
      when STATE_ERROR   then [:error, raw_response[1..-1]]
      end
    end
  end
end
