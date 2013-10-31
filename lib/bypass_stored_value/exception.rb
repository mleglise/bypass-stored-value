module BypassStoredValue
  class Exception
    class ActionNotFound < StandardError
      def message
        "This action is currently not implemented"
      end
    end

    class NoLineItems < StandardError
      def message
        "Hash of line items is missing"
      end
    end

    class NoPayments < StandardError
      def message
        "Hash of payments is missing"
      end
    end
  end
end
