module BypassStoredValue
  module Clients
    class CeridianClient < BypassStoredValue::Client
      attr_accessor :options

      def initialize(user, password, args= {})
        @merchant_name = args.fetch(:merchant_name, "Palace")
        @merchant_number = args.fetch(:merchant_number, "130006")
        @store_number = args.fetch(:store_number, "1234567890")
        @division = args.fetch(:division, "00000")
        @routingID = args.fetch(:routingID, "6006492606500000000")
        @test_mode = args.fetch(:test_mode, true)
        @user = user
        @password = password
        @mock = args.fetch(:mock, true)
        self.options = args
      end

      def settle(code, amount, tip = false)
        if tip
          tip(code, amount)
        else
          redeem(code,amount)
        end
      end

      def authorize(code, amount, tip)
        client.balance_inquiry(code)
      end

      def deduct(code, transaction_id, amount)
        raise NotImplementedError
      end

      def reload_account(code, amount)
        client.reload(code, amount)
      end

      def check_balance(code)
        client.balance_inquiry(code)
      end

      def balance_inquiry(card_number)
        resp = make_request(:balance_inquiry, build_request(
                {card: card_info(card_number),
                amount: {
                    amount: '0.00',
                    currency: 840
                },
                check_for_duplicate: 'false',
                transactionID: '',
                stan: Time.now.strftime('%H%M%S'),
                routingID: @routingID
                })
              )
      end

      def cancel(card_number, amount, stan)
        make_request(:cancel, build_request(
            {
              card: card_info(card_number),
              date: Time.now.strftime('%FT%T%:z'),
              transaction_amount: {
                amount: amount,
                currency: 'USD'
             },
              stan: stan,
              routingID: @routingID

            }
          )
        )
      end

      def redeem(card_number, amount)
        make_request(:redemption, build_request(
            {
              card: card_info(card_number),
              date: Time.now.strftime('%FT%T%:z'),
              transactionID: '',
              check_for_duplicate: 'false',
              redemption_amount: {
                amount: amount,
                currency: 'USD'
              },
              stan: Time.now.strftime('%H%M%S'),
              routingID: @routingID
            }
          )
        )
      end

      def reload(card_number, amount)
        make_request(:reload, build_request(
            {
              card: card_info(card_number),
              transactionID: '',
              reload_amount: {
                 amount: amount,
                 currency: 'USD'
             }

            }
          )
        )

      end

      def tip(card_number, amount)
        make_request(:tip, build_request(
            {
              card: card_info(card_number),
              tip_amount: {
                amount: amount,
                currency: 'USD'
               },
              transactionID: '',
              check_for_duplicate: 'false',
              stan: Time.now.strftime('%H%M%S'),
              routingID: @routingID
            }

          )
        )

      end

      def reversal(card_number, amount, stan)
        make_request(:reversal, build_request(
            {
              card: card_info(card_number),
              transaction_amount: {
                amount: amount,
                currency: 'USD'
               },
              routingID: @routingID,
              stan: stan
            }
          )
        )

      end

      def issue_gift_card(card_number, amount, pin = '', expiration = '', stan)
        make_request(:issue_gift_card, build_request(
            {
              card: card_info(card_number),
             issue_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: '',
             check_for_duplicate: 'false',
             stan: stan,
             routingID: @routingID
            }
          )
        )

      end

      def pre_auth(card_number, amount, stan = Time.now.strftime('%H%M%S'))
        make_request(:pre_auth, build_request(
            {
              card: card_info(card_number),
              requested_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: '',
             check_for_duplicate: 'false',
             stan: stan,
             routingID: @routingID
            }
          )
        )
      end

      def pre_auth_complete(card_number, amount, stan)
        make_request(:pre_auth, build_request(
            {
              card: card_info(card_number),
              transaction_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: '',
             check_for_duplicate: 'false',
             stan: stan,
             routingID: @routingID
            }
          )
        )
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

        def make_request(action, message)
          return BypassStoredValue::MockResponse.new(message.values[0]) if @mock == true
          response = client.call(action,
            message: message)
          handle_response response, action
        end

        def handle_response(response, action)
          BypassStoredValue::CeridianResponse.new(response, action)
        end

        def merchant_info
          {
            merchant:{
              merchant_name: @merchant_name,
              merchant_number: @merchant_number,
              store_number: @store_number,
              division: @division
            }
          }
        end

        def card_info(card_number)
          {
              card_number: card_number,
              card_currency: 840,
              pin_number: "",
              card_expiration: "",
              card_track_one: "",
              card_track_two: "",
           }
        end

        def build_request(message)
          {
            request: {
            invoice_number: '12345678',
            date: Time.now.strftime('%FT%T%:z')
            }.merge(message).merge(merchant_info)
          }
        end

        def wsdl
          @test_mode ? File.join(BypassStoredValue.root, 'wsdls', 'ceridian_test.wsdl.xml') : File.join(BypassStoredValue.root, 'wsdls', 'ceridian_production.wsdl.xml')
        end

    end
  end
end