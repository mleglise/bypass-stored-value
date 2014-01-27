module BypassStoredValue
  class Response
    attr_accessor :response, :result, :action, :transaction_id, :message

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
