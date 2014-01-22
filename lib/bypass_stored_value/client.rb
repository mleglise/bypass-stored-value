module BypassStoredValue
  class Client
    def settle(code, amount, tip = false)
      raise NotImplementedError
    end

    def authorize(code, amount, tip = false)
      raise NotImplementedError
    end

    def post_transaction(line_items = nil, amount = nil)
      BypassStoredValue::Response.new nil, :post_transaction
    end

    def check_balance
      raise NotImplementedError
    end

    def reload_account(code, amount)
      raise NotImplementedError
    end

    def issue(code, amount)
      raise NotImplementedError
    end

    def refund(code, transaction_id, amount, original_amount)
      raise NotImplementedError
    end

  end
end
