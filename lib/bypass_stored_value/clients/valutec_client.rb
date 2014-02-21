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
        log_lvl = production? ? :error : :debug
        @client ||= Savon.client do
          wsdl 'http://ws.valutec.net/Valutec.asmx?WSDL'
          log_level log_lvl
        end
      end

      def make_request(action, card_number, amount, message)
        client.call(action)
      end

      def program_types
        [:gift, :loyalty]
      end

      def transaction_types
        %w(
          Activation
          AddValue
          Balance
          CashOut
          CreateCard
          Current_Day_Totals
          Deactivate
          Previous_Day_Totals
          Replace
          Restaurant_Sale
          Sale
          Void
        )
      end

      def actions
        %w(
          CardRegistration
          Registration_Get
          Registration_Set
          Registration_SetEx
          Transaction_ActivateCard
          Transaction_AddValue
          Transaction_AdjustBalance
          Transaction_CardBalance
          Transaction_Cardless
          Transaction_CardlessEx
          Transaction_CashOut
          Transaction_CreateCard
          Transaction_DeactivateCard
          Transaction_Generic
          Transaction_HostTotals
          Transaction_ReplaceCard
          Transaction_RestaurantSale
          Transaction_Sale
          Transaction_Void
        )
      end
    end
  end
end
