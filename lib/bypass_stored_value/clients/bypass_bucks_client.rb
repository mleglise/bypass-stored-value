require 'faraday'

module BypassStoredValue
  module Clients
    class BypassBucksClient < BypassStoredValue::Client
      attr_accessor :options

      def initialize(user, password, args= {})
        @user = user
        @password = password
        self.options = args
        @test_mode = args.fetch(:test_mode, true)
        @mock = args.fetch(:mock, false)
      end

      #Line Items need to be an array of arrays like [["skunumber", "cost", "qty"],["skunumber", "cost", "qty"]],
      # ex) [["124556", "19.99", "3"]]
      # you pass in the same sku twice also, [["124556", "19.99", "3"], ["124556", "19.99", "1"]]  , same as [["124556", "19.99", "4"]]
      def settle(card_number, amount, tip = false, line_items = nil)
        redeem(card_number, (amount.to_f*100).to_i, line_items)
      end

      def authorize(card_number, amount, tip = false)
        raise NotImplementedError
      end

      def post_transaction(line_items = nil, amount = nil)
        BypassStoredValue::Response.new nil, :post_transaction
      end

      def check_balance(card_number)
        get_balance(card_number)
      end

      #
      def issue(card_number, amount)
        activate(card_number, (amount.to_f*100).to_i)
      end

      def refund(card_number, transaction_code, amount)
        increment(card_number, (amount.to_f*100).to_i)
      end

      #Activate
      def activate(card_number, amount)
        reference_number = "act#{card_number}"
        make_put_request("cards/#{card_number}/activate", {reference_number: reference_number, amount: (amount.to_f*100).to_i}, :activate)
      end

      #Redeem
      def redeem(card_number, amount, line_items)
        reference_number =  "red#{rand(10**12)}"
        make_put_request("cards/#{card_number}/redeem", {reference_number: reference_number, amount: (amount.to_f*100).to_i}, :redeem)
      end

      #Increment
      def increment(card_number, amount)
        reference_number = "inc#{card_number}#{rand(0..100)}"
        make_put_request("cards/#{card_number}/increment", {reference_number: reference_number, amount: (amount.to_f*100).to_i}, :increment)
      end

      #Balance
      def get_balance(card_number)
        make_get_request("cards/#{card_number}/get_balance",{reference_number:  "bal#{card_number}T#{Time.now.to_i}"}, :get_balance)
      end

      #Void - previous transaction

      def void(card_number, transaction_id)
        make_delete_request("cards/#{card_number}/transactions/#{transaction_id}", "del#{transaction_id}", :void)
      end

      private

      def make_put_request(url, params=nil, method)
        return BypassStoredValue::MockResponse.new({}) if @mock == true
        response = client.put do |req|
          req.url url
          req.options[:timeout] = 15           # open/read timeout in seconds
          req.options[:open_timeout] = 5
          req.body = params.to_json
        end
        handle_response(response, method)
      end

      def make_get_request(url, params=nil, method)
        return BypassStoredValue::MockResponse.new({}) if @mock == true
        response = client.get do |req|
          req.url url
          req.options[:timeout] = 15           # open/read timeout in seconds
          req.options[:open_timeout] = 5
          req.params = params
        end
        handle_response(response, method)
      end

      def make_delete_request(url, params=nil, method)
        return BypassStoredValue::MockResponse.new({}) if @mock == true
        response = client.delete do |req|
          req.url url
          req.options[:timeout] = 15           # open/read timeout in seconds
          req.options[:open_timeout] = 5
          req.body = params.to_json
        end
        handle_response(response, method)
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
        @test_mode ? "https://bypassbucks-integration.bypasslane.com" : "https://bypassbucks.bypasslane.com"
      end

      def handle_response(response, method)
        BypassStoredValue::BypassBucksResponse.new(response, method)
      end

    end
  end
end
