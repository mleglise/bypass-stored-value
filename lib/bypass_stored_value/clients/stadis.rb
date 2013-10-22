module BypassStoredValue
  module Clients
    class StadisClient
      # this next line makes me sad. who wrote this?
      def initialize(protocol, host, port, location_id, register_id, reference_number, vendor_id, vendor_cashier, userid, password)
        @protocol = protocol
        @host = host
        @port = port
        @location_id = location_id
        @vendor_id = vendor_id
        @vendor_cashier = vendor_cashier
        @register_id = register_id
        @reference_number = reference_number
        @userid = userid
        @password = password

        client
      end

      def client
        @client ||= Savon.client({
            endpoint: "#{@protocol}://#{@host}:#{@port}/StadisWeb/StadisTransactions.asmx",
            namespace: "http://www.STADIS.com/",
            read_timeout: 5000,
            open_timeout: 360,
            element_form_default: :unqualified,
            namespace_identifier: nil,

            ssl_verify_mode: :none,
            env_namespace: :soap,
            soap_header: {
              "SecurityCredentials" => {
                  "UserID" => @userid,
                  "Password" => @password
              },
              :attributes! => {"SecurityCredentials" => {"xmlns" => "http://www.STADIS.com/"}}
            }
          })
      end

      def soap_action(action)
        "http://www.STADIS.com/#{action}"
      end

      def balance(code)
        response = make_request("StadisBalanceCheck", {
              "StatusCheckInput" => {
                  "TransactionType" => 3,
                  "TenderTypeID" => 1,
                  "TenderID" => code,
                  "Amount" => 0
            }
          }
        )
        handle_response(response)
      end

      def account_charge(code, amount)
        response = make_request("StadisAccountCharge", {
              "ChargeInput" => {
                  "ReferenceNumber" => "byp_#{rand(10**6)}",
                  "RegisterID" => @register_id,
                  "VendorCashier" => @vendor_cashier,
                  "TransactionType" => 1,
                  "TenderTypeID" => 1,
                  "TenderID" => code,
                  "Amount" => amount
              }
          }
        )
        response = handle_response(response)
        {
            :return_code => response[:stadis_account_charge_response][:stadis_account_charge_result][:return_message][:return_code].to_i,
            :message => response[:stadis_account_charge_response][:stadis_account_charge_result][:return_message][:message],
            :stadis_authorization_id => response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:stadis_authorization_id],
            :charged_amount => response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:charged_amount].to_f,
            :remaining_amount => response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:remaining_amount].to_f,
            :account_status_message => response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:account_status_message]
        }
      end

      #post_transaction
      #  takes a code, amount, authorization_id
      def post_transaction(code, amount, authorization_id, line_items = nil, payments = nil)
        items = []
        line_items.each do |item|
          items << {
              "ItemID" => "#{item.item_id}",
              "Description" => item.item.name,
              "Dept" => "bypass",
              "Class" => "bypass",
              "SubClass" => "bypass",
              "Quantity" => item.count,
              "Price" => item.unit_price,
              "Cost" => item.unit_price,
              "Tax" => 0,
              "AdditionalTax" => 0,
              "Discount" => 0
          }
        end if line_items
        tenders = []
        total = 0
        payments.each do |payment|
          tenders << {
                "IsStadisTender" => payment.class == StadisPayment,
                "StadisAuthorizationID" => (payment.class == StadisPayment) ? authorization_id : "",
                "TenderTypeID" => (payment.class == StadisPayment) ? 1 : ((payment.class == CashPayment) ? 2 : 3),
                "TenderID" => (payment.class == StadisPayment) ? code : '',
                "Amount" => payment.amount
          }
          total += payment.amount
        end if payments

        response = make_request("PostTransaction", {
              "Header" => {
                  "LocationID" => @location_id,
                  "RegisterID" => @register_id,
                  "ReceiptID" => "byp_#{rand(10**6)}",
                  "VendorID" => @vendor_id,
                  "VendorCashier" => @vendor_cashier,
                  "VendorDiscountPct" => "0",
                  "VendorDiscount" => 0,
                  "VendorTax" => 0,
                  "VendorTip" => 0,
                  "SubTotal" => total,
                  "Total" => total
              },
              "Items" => { "StadisTranItem" => items },
              "Tenders" => { "StadisTranTender" => tenders }
          }
        )
        response = handle_response(response)
        {
            :return_code => response[:post_transaction_response][:post_transaction_result][:return_message][:return_code].to_i,
            :message => response[:post_transaction_response][:post_transaction_result][:return_message][:message],
            :assigned_key => response[:post_transaction_response][:post_transaction_result][:assigned_key]
        }
      end

      def refund(code, authorization_id, amount)
        response = make_request("ReverseStadisAccountCharge", {
            "ReverseChargeInput" => {
              "ReferenceNumber" => authorization_id,
              "RegisterID" => @register_id,
              "VendorCashier" => @vendor_cashier,
              "TransactionType" => 2,
              "TenderTypeID" => 1,
              "TenderID" => code,
              "Amount" => amount
            }
          }
        )
        body = handle_response(response)
        result = body[:reverse_stadis_account_charge_response][:reverse_stadis_account_charge_result]
        {
            :return_code => result[:return_message][:return_code],
            :message => result[:return_message][:message],
            :remaining_amount => result[:stadis_reply][:remaining_amount]
        }
      end

      def account_reload(code, amount)
        response = make_request("StadisAccountReload", {
              "ReloadInput" => {
                  "ReferenceNumber" => "byp_#{rand(10**6)}",
                  "RegisterID" => @register_id,
                  "VendorCashier" => @vendor_cashier,
                  "TransactionType" => 3,
                  "TenderTypeID" => 1,
                  "TenderID" => code,
                  "Amount" => amount
              }
          })
        response = handle_response(response)
        {
            :return_code => response[:stadis_account_reload_response][:stadis_account_reload_result][:return_message][:return_code],
            :message => response[:stadis_account_reload_response][:stadis_account_reload_result][:return_message][:message],
            :remaining_amount => response[:stadis_account_reload_response][:stadis_account_reload_result][:stadis_reply][:remaining_amount]
        }
      end

      private

      def make_request(action, message)
        @client.call(action,
          soap_action: soap_action(action),
          message: message
          )
      end

      def handle_response(response)
        response.body unless response.nil? || response.body.nil?
      end
    end
  end
end
