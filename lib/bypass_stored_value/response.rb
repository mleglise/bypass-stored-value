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

    def deep_find(key, object, found=nil)
      if object.respond_to?(:key?) && object.key?(key)
        return object[key]
      elsif object.is_a? Enumerable
        object.find { |*a| found = deep_find(key, a.last) }
        return found
      end
    end
  end
end
