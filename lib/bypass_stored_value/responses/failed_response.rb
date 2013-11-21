module BypassStoredValue
  class FailedResponse < BypassStoredValue::Response
    def successful?
      false
    end
  end
end