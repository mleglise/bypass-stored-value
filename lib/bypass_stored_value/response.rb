module BypassStoredValue
  class Response
    attr_accessor :response, :result, :action, :transaction_id

    def successful?
      true
    end

    def balance
      raise NotImplementedError
    end

  end
end
