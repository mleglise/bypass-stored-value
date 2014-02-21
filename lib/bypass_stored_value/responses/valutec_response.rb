module BypassStoredValue
  class ValutecResponse < BypassStoredValue::Response
    def errors
      # parse output for ErrorMsg response field
    end
  end
end

