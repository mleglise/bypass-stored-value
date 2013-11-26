module BypassStoredValue
  module Clients
    class GivexClient < BypassStoredValue::Client
      attr_accessor :options

      def initialize(user, password, args= {})
        @user = user
        @password = password
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

      #functions on service
      def get_balance(card_number)
        make_request(:GetBalance, card_number, {
                  id: user_info,
                  givexNumber: card_number,
                  additionalData: ''
                })
      end

      private
        def production?
          options[:production] == true
        end

        def client
          namespaces = {"xmlns:tns" => "https://gapi.givex.com/1.0/binding_trans",
                        "xmlns:tns" => "https://gapi.givex.com/1.0/binding_admin",
                        "xmlns:tns" => "https://gapi.givex.com/1.0/messages_trans",
                        "xmlns:tns" => "https://gapi.givex.com/1.0/messages_admin",
                        "xmlns:gvxAdmin" => "https://gapi.givex.com/1.0/messages_admin",
                        "xmlns:gvxGlobal" => "https://gapi.givex.com/1.0/messages_global",
                        "xmlns:gvxCommon" => "https://gapi.givex.com/1.0/types_common",
                        "xmlns:gvxTrans" => "https://gapi.givex.com/1.0/types_trans"

          }
          @client ||= Savon.client({
            endpoint: end_point,
            namespace: 'https://gapi.givex.com/1.0/types_trans',
            namespaces: namespaces,
            pretty_print_xml: true,
            convert_request_keys_to: :none,
            log_level: production? ? :error : :debug
          })
          @client
        end

        def make_request(action, card_number, message)
          return BypassStoredValue::MockResponse.new(message.values[0]) if @mock == true
          response = client.call(action, message: message)
          givex_response = handle_response(response, action)

          givex_response

        #rescue
        #  BypassStoredValue::FailedResponse.new(nil, action, "Trouble taking to service.")
        end

        def handle_response(response, action)
          BypassStoredValue::GivexResponse.new(response, action)
        end

        def end_point
          'https://gapi.givex.com:50081/1.0/trans/'
        end

        def user_info
          {
            token: '999847a0d5905eb414e8c720a5bd5',
            user: @user,
            userPasswd: @password,
            language: 'en'
          }
        end
    end
  end
end