require 'faraday'

module BypassStoredValue
  module Clients
    class GivexClient < BypassStoredValue::Client
      attr_accessor :options

      def initialize(user, password, args= {})
        @user = user
        @password = password
        self.options = args
        @test_mode = args.fetch(:test_mode, true)
        @mock = args.fetch(:mock, false)
      end

      def settle(card_number, amount, tip = false)
        redeem(card_number, amount, rand(10**12))
      end

      def authorize(card_number, amount, tip = false)
        BypassStoredValue::GivexResponse.new({}, 'dc_920', true)
      end

      def post_transaction(line_items = nil, amount = nil)
        BypassStoredValue::Response.new nil, :post_transaction
      end

      def check_balance(card_number)
        get_balance(card_number)
      end
      #
      def reload_account(card_number, amount)
        increment card_number, amount
      end
      #
      def issue(card_number, amount)
        activate(card_number, amount)
      end

      def refund(card_number, transaction_code, amount)
        cancel(card_number, amount, transaction_code)
      end

      #givex functions

      #NULL
      def ping
        make_request('dc_900')
      end

      #Secure Redemption
      def redeem(card_number, amount, transaction_code)
        make_request('dc_901', get_params(transaction_code, card_number, amount), transaction_code)
      end

      #Activate
      def activate(card_number, amount)
        transaction_code = "act#{card_number}"
        make_request('dc_906', get_params(transaction_code, card_number, amount), transaction_code)
      end

      #Activate
      def increment(card_number, amount)
        transaction_code = "inc#{card_number}"
        make_request('dc_905', get_params(transaction_code, card_number, amount), transaction_code)
      end

      #Cancel
      def cancel(card_number, amount, transaction_code)
        make_request("dc_907", get_params(transaction_code, card_number, amount), transaction_code)
      end

      #Adjustment
      def adjustment(card_number, amount)
        transaction_code = "adj#{card_number}#{rand(0..100)}"
        make_request("dc_908", get_params(transaction_code, card_number, amount), transaction_code)
      end

      #Balance
      def get_balance(card_number)
        transaction_code = "bal#{card_number}"
        params = ["en", "#{transaction_code}", @user, card_number]
        make_request('dc_909', params, transaction_code)
      end

      private

        def make_request(method, params=nil, transaction_code=nil)
          return BypassStoredValue::MockResponse.new({}) if @mock == true
          data = {
              jsonrpc: "2.0",
              method: "#{method}",
              params: (params.nil? ? nil : params),
              id: "#{transaction_code}"
          }
          response = client.post("/", data.to_json)
          handle_response(response, method)

        #rescue
        #  BypassStoredValue::FailedResponse.new(nil, method, "Trouble talking to service.")
        end

        def client
          return @client if @client

          connection = Faraday.new(end_point, ssl:{verify:false}) do |builder|
            builder.adapter :net_http
          end
          connection.headers['Content-Type'] = "application/json"
          connection.basic_auth(@user, @password)

          @client = connection
        end

        def end_point
          @test_mode ? "https://dev-dataconnect.givex.com:50101" : "https://gapi.givex.com:50101"
        end

        def handle_response(response, method)
          BypassStoredValue::GivexResponse.new(response, method)
        end

        def get_params(transaction_code, card_number, amount)
          ["en", "#{transaction_code}", @user, @password, card_number, amount.to_s]
        end
    end
  end
end