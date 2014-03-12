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
      errors.nil? || errors.empty? || @message == 'Approved'
    end

    def errors
      @response.all_values_for_key(:error_msg).join(',') if @response
    end
  end
end

