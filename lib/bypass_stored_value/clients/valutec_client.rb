module BypassStoredValue
  module Clients
    class ValutecClient < BypassStoredValue::Client
      attr_reader :client
      attr_accessor :options

      def initialize(user, password, args={})
        @user = user
        @password = password
        @client_key = args.fetch(:client_key)
        self.options = options
        client
      end

      def settle(code, amount, tip = false)
        raise NotImplementedError
      end

      def authorize(code, amount, tip = false)
      end

      def post_transaction(line_items = nil, amount = nil)
        BypassStoredValue::Response.new nil, :post_transaction
      end

      def check_balance
        raise NotImplementedError
      end

      def reload_account(code, amount)
        raise NotImplementedError
      end

      def issue(code, amount)
        raise NotImplementedError
      end

      def refund(code, transaction_id, amount, original_amount)
        {
          RequestAuthCode: transaction_id,
        }
      end

    private
      def production?
        options[:production] == true
      end

      def client
        log_lvl = production? ? :error : :debug
        @client ||= Savon.client do
          wsdl 'http://ws.valutec.net/Valutec.asmx?WSDL'
          log_level log_lvl
        end
      end

      def handle_error(error_response, action)
        BypassStoredValue::FailedResponse(error_response, action, "Trouble talking to service.")
      end

      def handle_response(response, action)
        BypassStoredValue::ValutecResponse.new(response, action)
      end

      def program_types
        [:gift, :loyalty]
      end

      def make_request(action, message)
        response = client.call(action.to_sym, message: message)
        handle_response(response, action)
      end

      def transaction_types
        %w(
          Activation AddValue Balance
          CashOut CreateCard Current_Day_Totals
          Deactivate Previous_Day_Totals Replace
          Restaurant_Sale Sale Void
        )
      end

      # Might not be obvious:
      #   This creates a method for every action defined within this
      #   array. Method parameters are set from within the define_method
      #   block
      %w(
        CardRegistration Registration_Get Registration_Set
        Registration_SetEx Transaction_ActivateCard Transaction_AddValue
        Transaction_AdjustBalance Transaction_CardBalance Transaction_Cardless
        Transaction_CardlessEx Transaction_CashOut Transaction_CreateCard
        Transaction_DeactivateCard Transaction_Generic Transaction_HostTotals
        Transaction_ReplaceCard Transaction_RestaurantSale Transaction_Sale
        Transaction_Void
      ).each do |action|
        method_name = action.underscore
        define_method(method_name.to_sym) do |card_number, amount, message|
        end
      end
    end
  end
end
