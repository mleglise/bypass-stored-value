module BypassStoredValue
  module Clients
    class ValutecClient
      attr_reader :client

      def initialize(user, password, args={})
        @user = user
        @password = password
        @client_key = args.fetch(:client_key)
      end

      def settle(code, amount, tip = false)
        raise NotImplementedError
      end

      def authorize(code, amount, tip = false)
        raise NotImplementedError
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
      def client
        @client ||= Savon.client do
          wsdl 'http://ws.valutec.net/Valutec.asmx?WSDL'
        end
      end

      def program_types
        [:gift, :loyalty]
      end

      def transaction_types
        [
          "Sale", "Activation", "AddValue",
          "Void", "Balance", "Current_Day_Totals",
          "Previous_Day_Totals", "Deactivate", "Replace",
          "CreateCard", "Restaurant_Sale", "CashOut"
        ]
      end

      def make_request(action, card_number, amount, message)
        client.call(action)
      end
    end
  end
end
