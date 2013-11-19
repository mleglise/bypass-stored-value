module BypassStoredValue
  module Clients
    class CeridianClient
      def initialize(user, password, args= {})
        ssl_info = {
          ssl_cert_file: File.join(BypassStoredValue.root, 'test.crt'),
          ssl_cert_key_file: File.join(BypassStoredValue.root, 'testkey.key'),
          ssl_ca_cert_file: File.join(BypassStoredValue.root, 'test.csr'),
          ssl_verify_mode: :none,
          ssl_version: :SSLv3
        }
        @merchant_name = args.fetch(:merchant_name, "")
        @merchant_number = args.fetch(:merchant_number, "")
        @store_number = args.fetch(:store_number, "")
        @division = args.fetch(:division, "")
        @test_mode = args.fetch(:test_mode, true)
        @user = user
        @password = password
        @savon_client = Savon.client({
          wsdl: wsdl,
          #env_namespace: :soapenv,
          wsse_auth: [@user, @password],
          pretty_print_xml: true
        }.merge(ssl_info))
      end

      def get_balance(card_number)
        response = @savon_client.call(:balance_inquiry, message: build_request(
                {card: {
                    card_number: card_number,
                    card_currency: 840
                },
                amount: {
                    amount: 0,
                    currency: 840
                },
                invoice_number: '1'})
              )
        handle_response response
      end

      def cancel(card_number, amount, pin = nil)
        response = @savon_client.call(:cancel, message: build_request(
            {
              card: {
                card_number: card_number,
                card_currency: 840,
                pin_number: pin
             },
             date: Time.now.strftime('%Y-%m-%dT00:00:00'),
             invoice_number: '1',
             transaction_amount: {
                 amount: amount,
                 currency: 'USD'
             }

            }
          )
        )
        handle_response response
      end

      def redeem
        response = @savon_client.call(:redemption, message: build_request(
            {
              card: {
                card_number: card_number,
                card_currency: 840,
                pin_number: pin
             },
             date: Time.now.strftime('%Y-%m-%dT00:00:00'),
             invoice_number: '1',
             transaction_id: rand(9999),
             check_for_duplicate: 'TRUE'

            }
          )
        )
        handle_response response
      end

      def reload(card_number, amount, pin = nil)
        response = @savon_client.call(:reload, message: build_request(
            {
              card: {
                card_number: card_number,
                card_currency: 840,
                pin_number: pin
             },
             date: Time.now.strftime('%Y-%m-%dT00:00:00'),
             invoice_number: '1',
             transaction_id: rand(9999),
             reload_amount: {
                 amount: amount,
                 currency: 'USD'
             }

            }
          )
        )
        handle_response response
      end

      def tip(card_number, amount, pin = nil)
        response = @savon_client.call(:tip, message: build_request(
            {
              card: {
                card_number: card_number,
                card_currency: 840,
                pin_number: pin
             },
             date: Time.now.strftime('%Y-%m-%dT00:00:00'),
             invoice_number: '1',
             transaction_id: rand(9999),
             tip_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             check_for_duplicate: 'TRUE'

            }
          )
        )
        handle_response response
      end

      def reversal(card_number, amount, pin = nil)
        response = @savon_client.call(:reversal, message: build_request(
            {
              card: {
                card_number: card_number,
                card_currency: 840,
                pin_number: pin
             },
             date: Time.now.strftime('%Y-%m-%dT00:00:00'),
             invoice_number: '1',
             transaction_amount: {
                 amount: amount,
                 currency: 'USD'
             }

            }
          )
        )
        handle_response response
      end

      def issue_gift_card(card_number, amount, pin, expiration)
        response = @savon_client.call(:issue_gift_card, message: build_request(
            {
              card: {
                card_number: card_number,
                card_currency: 840,
                pin_number: pin,
                card_expiration: expiration
             },
             date: Time.now.strftime('%Y-%m-%dT00:00:00'),
             invoice_number: '1',
             issue_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             check_for_duplicate: 'TRUE'

            }
          )
        )
        handle_response response
      end

      def get_operations
        @savon_client.operations
      end


      private

      def handle_response(response)
        #TODO - do something with the response
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

      def build_request(message)
        {
          request: {
          }.merge(message).merge(merchant_info)
        }
      end

      def wsdl
        @test_mode ? File.join(BypassStoredValue.root, 'wsdls', 'ceridian_test.wsdl.xml') : File.join(BypassStoredValue.root, 'wsdls', 'ceridian_production.wsdl.xml')
      end

      def server_name
        @test_mode ? "webservices-cert.storedvalue.com" : "webservices.storedvalue.com"
      end

    end
  end
end