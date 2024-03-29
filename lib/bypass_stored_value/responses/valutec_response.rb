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
        parse
      end
    end

    def successful?
      @message == 'Approved' || errors.nil? || errors.empty?
    end

    def errors
      @response.all_values_for_key(:error_msg).join(',') if @response
    end

    def balance
      result[:remaining_balance]
    end

    private

      ACTIONS = [:transaction_restaurant_sale, :transaction_card_balance, :transaction_add_value, :transaction_activate_card]

      def parse
        raise BypassStoredValue::Exception::ActionNotFound unless ACTIONS.include?(action)
        send("parse_#{ action }_response")
        result
      end

      def parse_transaction_restaurant_sale_response
        set_result(response[:transaction_restaurant_sale_response][:transaction_restaurant_sale_result])
      end

      def parse_transaction_card_balance_response
        set_result(response[:transaction_card_balance_response][:transaction_card_balance_result])
      end

      def parse_transaction_add_value_response
        set_result(response[:transaction_add_value_response][:transaction_add_value_result])
      end

      def parse_transaction_activate_card_response
        set_result(response[:transaction_activate_card_response][:transaction_activate_card_result])
      end

      def set_result(response_hash)
        @result = {
          authentication_token: response_hash[:authorization_code],
          charged_amount: response_hash[:card_amount_used],
          remaining_balance: response_hash[:balance],
          message: @message
        }
      end
  end
end

