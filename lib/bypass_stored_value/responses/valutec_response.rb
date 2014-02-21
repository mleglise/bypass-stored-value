module BypassStoredValue
  class ValutecResponse < BypassStoredValue::Response
    attr_accessor :response, :result, :action

    def initialize(response, action, return_successful=false)
      @response = response.try(:body)
      @action = action

      if return_successful
        @message = 'Approved'
      else
        @message = errors
      end
    end

    def parse

    end

    def successful?
      errors.nil? || errors.empty?
    end

    def errors
      deep_find(:error_msg, @response)
    end
  end
end

