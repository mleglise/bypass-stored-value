module BypassStoredValue
  module Clients
    class ValutecClient < BypassStoredValue::Client
      attr_reader :client, :options, :client_key, :server_id,
                  :identifier

      define_action :registration_get, :registration_set,
                    :registration_set_ex, :transaction_activate_card,
                    :transaction_add_value, :transaction_adjust_balance,
                    :transaction_card_balance, :transaction_cardless,
                    :transaction_cardless_ex, :transaction_cash_out,
                    :transaction_create_card, :transaction_deactivate_card,
                    :transaction_generic, :transaction_host_totals,
                    :transaction_replace_card, :transaction_restaurant_sale,
                    :transaction_sale, :transaction_void

      def initialize(args={})
        @client_key  = args.fetch(:client_key) #provided by Valutec
        @terminal_id = args.fetch(:terminal_id) #provided by Valutec, does not map to Terminal ID in Bypass Backend
        @server_id   = args.fetch(:server_id) #map to Bypass Order Taker ID, optional in Valutec's system
        @identifier  = args.fetch(:identifier) #map to Bypass Order ID, optional in Valutec's system
        @location_id = args.fetch(:location_id) #provided by Valutec, does not map to Location ID in Bypass Backend

        @options = args
        client
      end

      def settle(code, amount, tip_amount=0)
        BypassStoredValue::ValutecResponse.new(nil, 'settle', true)
      end

      def authorize(code, amount, is_tip=false)
        amount, tip_amount = handle_amount(amount, is_tip)

        transaction_restaurant_sale(basic_request_params.merge({
          TipAmount: tip_amount,
          Amount: amount,
          CardNumber: code
        }))
      end

      def post_transaction(line_items = nil, amount = nil)
        BypassStoredValue::Response.new nil, :post_transaction
      end

      def check_balance(code)
        transaction_card_balance(basic_request_params.merge({
          CardNumber: code
        }))
      end

      def reload_account(code, amount)
        raise NotImplementedError
      end

      def issue(code, amount)
        transaction_activate_card(basic_request_params.merge({
          CardNumber: code,
          Amount: amount
        }))
      end

      def refund(code, transaction_id, amount=nil) #amount is always submitted by the backend, but not needed here
        transaction_add_value(basic_request_params.merge({
          CardNumber: code,
          Amount: amount,
          RequestAuthCode: transaction_id
        }))
      end

    private
      def production?
        options[:production] == true
      end

      def client
        log_lvl = production? ? :error : :debug
        @client ||= Savon.client(
          wsdl: File.join(BypassStoredValue.root, 'wsdls', 'valutec.wsdl'),
          element_form_default: :unqualified,
          namespace_identifier: nil,
          env_namespace: :soap,
          log_level: log_lvl,
          convert_request_keys_to: :camelcase
        )
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

      def basic_request_params
        {
           ClientKey:   @client_key,
           TerminalID:  @terminal_id,
           ProgramType: 'Gift',
           ServerID:    @server_id,
           Identifier:  @identifier
        }
      end

      def handle_amount(amount, is_tip)
        if is_tip
          tip_amount  = amount
          amount = 0
        else
          tip_amount  = 0
        end
        [amount, tip_amount]
      end
    end
  end
end
