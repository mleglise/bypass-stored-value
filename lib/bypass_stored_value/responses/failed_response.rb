module BypassStoredValue
  class FailedResponse < BypassStoredValue::Response
    attr_accessor :message
    def initialize(response, action, message = "")
      @response = response
      @action = action
      @message = message
    end
    def successful?
      false
    end
  end
end