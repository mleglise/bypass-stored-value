module BypassStoredValue
  class Exception
    class ActionNotFound < StandardError
      def message
        "This action is currently not implemented"
      end
    end
  end
end
