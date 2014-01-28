module BypassStoredValue
  class GivexResponse < BypassStoredValue::Response

    attr_accessor :balance

    def initialize(response, method, return_successful = false)
      @response = response
      @action = method
      @return_successful = return_successful

      parse_response(response, method) unless return_successful
    end

    def successful?
      return true if @return_successful
      @result[1] == '0' rescue false
    end

    private

      def parse_response(response, method)
        json = JSON.parse(response.body, {symbolize_names: true})
        @result = json[:result]

        if successful?
          case method
            when 'dc_909'
              parse_balance_inquiry(@result)
            when 'dc_901', 'dc_905', 'dc_906', 'dc_907', 'dc_908', 'dc_918'
              parse_balance_from_transaction(@result)
          end
        else
          @message = "Error #{@result[1]} : #{@result[2]}"
        end

        @transaction_id = @result[0] rescue nil
      end

      def parse_balance_inquiry(result)
        @balance = result[2].to_f*100.00.round/100
      end

      def parse_balance_from_transaction(result)
        @balance = result[3].to_f*100.00.round/100
      end
  end
end