module BypassStoredValue
  class GivexResponse < BypassStoredValue::Response

    attr_accessor :response, :result, :action, :transaction_id

    def initialize(response, action)
      @response = response
      @action = action
    end

    def successful?
      true
    end

    def balance
      raise NotImplementedError
    end
  end
end