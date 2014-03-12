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

    ACTIONS = [:transaction_restaurant_sale, :transaction_card_balance, :transaction_void]

    def parse
      raise BypassStoredValue::Exception::ActionNotFound unless ACTIONS.include?(action)
      send("parse_#{ action }_response")
      result
    end

    def successful?
      @message == 'Approved' || errors.nil? || errors.empty?
    end

    def errors
      @response.all_values_for_key(:error_msg).join(',') if @response
    end

    private

      def parse_transaction_restaurant_sale_response
        set_result(response[:transaction_restaurant_sale_response][:transaction_restaurant_sale_result])
      end

      def parse_transaction_card_balance_response
        set_result(response[:transaction_card_balance_response][:transaction_card_balance_result])
      end

      def parse_transaction_void_response
        set_result(response[:transaction_void_response][:transaction_void_result])
      end

      def set_result(response_hash)
        @result = {
          authentication_token: response_hash[:authorization_code],
          charged_amount: response_hash[:card_amount_used],
          remaining_balance: response_hash[:balance]
        }
      end
  end
end

