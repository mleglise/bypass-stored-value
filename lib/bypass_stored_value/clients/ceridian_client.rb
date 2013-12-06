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
        @mock = args.fetch(:mock, false)
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
        #balance_inquiry(code)  #This is really slow, and anywhere would time out, so setting to true at this time, anywhere check balance as it is.
        BypassStoredValue::CeridianResponse.new({}, :authorize, true)
      end

      def refund(code, transaction_id, amount)
        cancel(code, amount, transaction_id)
      end

      def reload_account(code, amount)
        card_recharge(code, amount)
      end

      def check_balance(code)
        balance_inquiry(code)
      end

      def issue(code, amount)
        issue_gift_card code, amount
      end

      def balance_inquiry(card_number)
        resp = make_request(:balance_inquiry, card_number, 0.0, build_request(
                {card: card_info(card_number),
                amount: {
                    amount: '0.00',
                    currency: 840
                },
                check_for_duplicate: 'false',
                transactionID: "#{rand(10**6)}",
                stan: Time.now.strftime('%H%M%S'),
                routingID: @routingID
                })
              )
      end

      def cancel(card_number, amount, stan)
        count = 0
        ceridian_response = nil

        while (ceridian_response.nil? or ceridian_response.return_code == '15') and count < 3 do
          ceridian_response = make_request(:cancel, card_number, amount, build_request(
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
          count += 1
        end

        if count == 3 or ceridian_response.nil?
          BypassStoredValue::FailedResponse.new(nil, :cancel, "Trouble taking to service.")
        else
          ceridian_response
        end
      end

      def redeem(card_number, amount)
        make_request(:redemption, card_number, amount, build_request(
            {
              card: card_info(card_number),
              date: Time.now.strftime('%FT%T%:z'),
              transactionID: "#{rand(10**6)}",
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

      def card_recharge(card_number, amount)
        make_request(:card_recharge, card_number, amount, build_request(
            {
              card: card_info(card_number),
              transactionID: "#{rand(10**6)}",
              recharge_amount: {
                 amount: amount,
                 currency: 'USD'
             },
              check_for_duplicate: 'false',
              stan: Time.now.strftime('%H%M%S'),
              routingID: @routingID

            }
          )
        )

      end

      def tip(card_number, amount)
        make_request(:tip, card_number, amount, build_request(
            {
              card: card_info(card_number),
              tip_amount: {
                amount: amount,
                currency: 'USD'
               },
              transactionID: "#{rand(10**6)}",
              check_for_duplicate: 'false',
              stan: Time.now.strftime('%H%M%S'),
              routingID: @routingID
            }

          )
        )

      end

      def issue_gift_card(card_number, amount, pin = '', expiration = '', stan = Time.now.strftime('%H%M%S'))
        make_request(:issue_gift_card, card_number, amount, build_request(
            {
              card: card_info(card_number),
             issue_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: "#{rand(10**6)}",
             check_for_duplicate: 'false',
             stan: stan,
             routingID: @routingID
            }
          )
        )

      end

      def pre_auth(card_number, amount, stan = Time.now.strftime('%H%M%S'))
        make_request(:pre_auth, card_number, amount, build_request(
            {
              card: card_info(card_number),
              requested_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: "#{rand(10**6)}",
             check_for_duplicate: 'false',
             stan: stan,
             routingID: @routingID
            }
          )
        )
      end

      def pre_auth_complete(card_number, amount, stan)
        make_request(:pre_auth, card_number, amount, build_request(
            {
              card: card_info(card_number),
              transaction_amount: {
                 amount: amount,
                 currency: 'USD'
             },
             transactionID: "#{rand(10**6)}",
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

        def make_request(action, card_number, amount, message)
          return BypassStoredValue::MockResponse.new(message.values[0]) if @mock == true
          count = 0
          ceridian_response = nil

          begin
            response = client.call(action, message: message)
            ceridian_response = handle_response(response, action)
          rescue => e
            #A timeout will come here
            puts e
          end

          while (ceridian_response.nil? or ceridian_response.return_code == '15') and count < 3 and action != :cancel and action != :balance_inquiry do        #don't do reversals for cancels
            ceridian_response = reversal(card_number, amount, message[:request][:stan]) if message[:request] and message[:request][:stan]
            count += 1
          end

          if (count == 3 or ceridian_response.nil?) and action != :cancel
            BypassStoredValue::FailedResponse.new(nil, action, "Trouble taking to service.")
          else
            ceridian_response
          end

        end

        def handle_response(response, action)
          BypassStoredValue::CeridianResponse.new(response, action)
        end

        def reversal(card_number, amount, stan)
          response = client.call(:reversal, message: build_request(
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
          handle_response response, :reversal

        rescue #rescue a timeout
          return nil

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