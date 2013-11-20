module BypassStoredValue
  class Response
    attr_accessor :response, :result, :action, :transaction_id

    def successful?
      true
    end

  end
end
