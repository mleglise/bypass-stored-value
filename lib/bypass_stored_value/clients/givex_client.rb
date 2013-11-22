module BypassStoredValue
  module Clients
    class GivexClient < BypassStoredValue::Client
      attr_accessor :options

      def initialize(user, password, args= {})
        self.options = args
      end

      def settle(code, amount, tip = false)
        raise NotImplementedError
      end

      def authorize(code, amount, tip = false)
        raise NotImplementedError
      end

      def deduct(code, transaction_id, amount)
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

      def issue
        raise NotImplementedError
      end

      def get_operations
        client.operations
      end

      private
        def production?
          options[:production] == true
        end

        def client
          @client ||= Savon.client({
            wsdl: wsdl,
            wsse_auth: [@user, @password],
            pretty_print_xml: true,
            log_level: production? ? :error : :debug
          })
          @client
        end

        def wsdl
          File.join(BypassStoredValue.root, 'wsdls', 'givex.wsdl')
        end
    end
  end
end