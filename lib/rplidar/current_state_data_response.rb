module Rplidar
  # Implementation of response to the GET_HEALTH request.
  class CurrentStateDataResponse < Response
    def response
      case raw_response[0]
      when STATE_GOOD    then { state: :good,    error_code: error_code }
      when STATE_WARNING then { state: :warning, error_code: error_code }
      when STATE_ERROR   then { state: :error,   error_code: error_code }
      end
    end

    def error_code
      (raw_response[2] << 8) + raw_response[1]
    end
  end
end
