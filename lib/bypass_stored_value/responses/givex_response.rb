module BypassStoredValue
  class GivexResponse < BypassStoredValue::Response

    attr_accessor :balance

    def initialize(response, method, return_successful = false)
      @response = response
      @action = method

      if return_successful

      else
        parse_response(response, method)
      end
    end

    def successful?
      @result[1] == '0'
    end

    private

      def parse_response(response, method)
        json = JSON.parse(response.body, {symbolize_names: true})
        @result = json[:result]

        if successful?
          case method
            when 'dc_909'
              parse_balance_inquiry(@result)
            when 'dc_901', 'dc_906', 'dc_907', 'dc_908'
              parse_balance_from_transaction(@result)
          end

          @transaction_id = @result[0]
        else
          @error = "Error #{@result[1]} : #{@result[2]}"
        end
      end

      def parse_balance_inquiry(result)
        @balance = result[2].to_f*100.00.round/100
      end

      def parse_balance_from_transaction(result)
        @balance = result[3].to_f*100.00.round/100
      end
  end
end