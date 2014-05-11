module BypassStoredValue
  class BypassBucksResponse < BypassStoredValue::Response

    attr_accessor :balance

    def initialize(response, method, return_successful = false)
      @response = response
      @action = method
      @return_successful = return_successful

      parse_response(response, method) unless return_successful
    end

    def successful?
      return true if @return_successful
      @result.has_key?(:error) == false
    end

    private

    def parse_response(response, method)
      @result = JSON.parse(response.body, {symbolize_names: true})
      if @result.has_key? :error
        @message = "Error #{@result[:error]}"
      else
        @balance = @result[:card][:balance] / 100
        @transaction_id = @result[:transaction][:id]
      end

    end
  end
end