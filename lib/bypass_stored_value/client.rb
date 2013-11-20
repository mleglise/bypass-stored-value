module BypassStoredValue
  class Client
    def settle(code, amount, tip = false)
      raise NotImplementedError
    end

    def authorize(code, amount, tip = false)
      raise NotImplementedError
    end

    def deduct(code, transaction_id, amount)
      raise NotImplementedError
    end

    def post_transaction(line_items = nil, amount = nil)
      BypassStoredValue::Response.new
    end
  end
end
