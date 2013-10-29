module BypassStoredValue
  module Clients
    class StadisClient
      attr_accessor :client, :protocol, :host, :port, :user, :password, :reference_number, :vendor_cashier, :vendor_id, :register_id, :location_id

      def initialize(user, password, args={})
        @protocol = args[:protocol]
        @host = args[:host]
        @port = args[:port]
        @vendor_cashier = args[:vendor_cashier]
        @vendor_id = args[:vendor_id]
        @register_id = args[:register_id]
        @location_id = args[:location_id]
        @reference_number = args[:reference_number]
        @user = user
        @password = password
        @mock = args[:mock]

        client
      end

      def client
        @client ||= Savon.client({
            endpoint: "#{protocol}://#{host}:#{port}/StadisWeb/StadisTransactions.asmx",
            namespace: "http://www.STADIS.com/",
            read_timeout: 5000,
            open_timeout: 360,
            element_form_default: :unqualified,
            namespace_identifier: nil,

            ssl_verify_mode: :none,
            env_namespace: :soap,
            soap_header: {
              "SecurityCredentials" => {
                  "UserID" => user,
                  "Password" => password
              },
              :attributes! => {"SecurityCredentials" => {"xmlns" => "http://www.STADIS.com/"}}
            }
          })
      end

      def soap_action(action)
        "http://www.STADIS.com/#{action}"
      end

      def balance(code)
        make_request("StadisBalanceCheck", {
              "StatusCheckInput" => {
                  "TransactionType" => 3,
                  "TenderTypeID" => 1,
                  "TenderID" => code,
                  "Amount" => 0}})
      end

      def account_charge(code, amount)
        make_request("StadisAccountCharge", {
            "ChargeInput" => {
              "ReferenceNumber" => "byp_#{rand(10**6)}",
              "RegisterID" => register_id,
              "VendorCashier" => vendor_cashier,
              "TransactionType" => 1,
              "TenderTypeID" => 1,
              "TenderID" => code,
              "Amount" => amount}})
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
                "IsStadisTender" => payment.class == StoredValuePayment,
                "StadisAuthorizationID" => (payment.class == StoredValuePayment) ? authorization_id : "",
                "TenderTypeID" => (payment.class == StoredValuePayment) ? 1 : ((payment.class == CashPayment) ? 2 : 3),
                "TenderID" => (payment.class == StoredValuePayment) ? code : '',
                "Amount" => payment.amount
          }
          total += payment.amount
        end if payments

        make_request("PostTransaction", {
              "Header" => {
                  "LocationID" => location_id,
                  "RegisterID" => register_id,
                  "ReceiptID" => "byp_#{rand(10**6)}",
                  "VendorID" => vendor_id,
                  "VendorCashier" => vendor_cashier,
                  "VendorDiscountPct" => "0",
                  "VendorDiscount" => 0,
                  "VendorTax" => 0,
                  "VendorTip" => 0,
                  "SubTotal" => total,
                  "Total" => total},
              "Items" => { "StadisTranItem" => items },
              "Tenders" => { "StadisTranTender" => tenders }})
      end

      def refund(code, authorization_id, amount)
        make_request("ReverseStadisAccountCharge", {
            "ReverseChargeInput" => {
              "ReferenceNumber" => authorization_id,
              "RegisterID" => register_id,
              "VendorCashier" => vendor_cashier,
              "TransactionType" => 2,
              "TenderTypeID" => 1,
              "TenderID" => code,
              "Amount" => amount}})
      end

      def reload_card(code, amount)
        make_request("ReloadGiftCard", {
          "ReloadGiftCard" => {
            "CardID" => code,
            "Amount" => amount}})
      end

      private

      def make_request(action, message)
        return BypassStoredValue::MockResponse.new(message.values[0]) if @mock == true
        response = client.call(action,
          soap_action: soap_action(action),
          message: message)
        BypassStoredValue::Response.new(response)
      end
    end
  end
end
