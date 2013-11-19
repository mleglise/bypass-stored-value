module BypassStoredValue
  module Clients
    class CeridianClient
      def initialize(user, password, args= {})
        #ssl_info = {
        #  ssl_cert_file: File.join(BypassStoredValue.root, 'test.crt'),
        #  ssl_cert_key_file: File.join(BypassStoredValue.root, 'testkey.key'),
        #  ssl_ca_cert_file: File.join(BypassStoredValue.root, 'test.csr'),
        #  ssl_verify_mode: :none,
        #  ssl_version: :SSLv3
        #}
        @merchant_name = args.fetch(:merchant_name, "Palace")
        @merchant_number = args.fetch(:merchant_number, "130006")
        @store_number = args.fetch(:store_number, "1234567890")
        @division = args.fetch(:division, "00000")
        @test_mode = args.fetch(:test_mode, true)
        @user = user
        @password = password
        @savon_client = Savon.client({
          wsdl: wsdl,
          wsse_auth: [@user, @password],
          pretty_print_xml: true
        })
      end

      def get_balance(card_number)
        response = @savon_client.call(:balance_inquiry, message: build_request(
                {card: card_info(card_number),
                amount: {
                    amount: '0.00',
                    currency: 840
                },
                check_for_duplicate: 'false',
                transactionID: ''
                })
              )
        handle_response response
      end

      #missing transactionID
      def cancel(card_number, amount, pin = nil)
        response = @savon_client.call(:cancel, message: build_request(
            {
              card: card_info(card_number),
              date: Time.now.strftime('%FT%T%:z'),
              transaction_amount: {
                amount: amount,
                currency: 'USD'
             }

            }
          )
        )
        handle_response response
      end

      def redeem(card_number, amount)
        response = @savon_client.call(:redemption, message: build_request(
            {
              card: card_info(card_number),
              date: Time.now.strftime('%FT%T%:z'),
              transactionID: '',
              check_for_duplicate: 'false',
              redemption_amount: {
                amount: amount,
                currency: 'USD'
              }
            }
          )
        )
        handle_response response
      end

      def reload(card_number, amount, pin = nil)
        response = @savon_client.call(:reload, message: build_request(
            {
              card: card_info(card_number),
              transactionID: '',
              reload_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             check_for_duplicate: 'false'
            }
          )
        )
        handle_response response
      end

      def tip(card_number, amount, pin = nil)
        response = @savon_client.call(:tip, message: build_request(
            {
              card: card_info(card_number),
              tip_amount: {
                amount: amount,
                currency: 'USD'
               },
              transactionID: '',
              check_for_duplicate: 'false'
            }
          )
        )
        handle_response response
      end

      def reversal(card_number, amount, pin = nil)
        response = @savon_client.call(:reversal, message: build_request(
            {
              card: card_info(card_number),
              transaction_amount: {
                amount: amount,
                currency: 'USD'
               }
            }
          )
        )
        handle_response response
      end

      def issue_gift_card(card_number, amount, pin = '', expiration = '')
        response = @savon_client.call(:issue_gift_card, message: build_request(
            {
              card: card_info(card_number),
             issue_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: '',
             check_for_duplicate: 'false'
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
        #ap response.hash
        response
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
          date: Time.now.strftime('%FT%T%:z'),
          routingID: '6006492606500000000',
          stan: Time.now.strftime('%H%M%S')
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