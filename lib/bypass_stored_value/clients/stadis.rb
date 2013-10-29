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
      def post_transaction(line_items = nil, payments = nil)
        request_data = set_up_transaction_request_data(line_items, payments)
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
                  "SubTotal" => request_data[:total],
                  "Total" => request_data[:total]},
              "Items" => { "StadisTranItem" => request_data[:items] },
              "Tenders" => { "StadisTranTender" => request_data[:tenders] }})
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

      def set_up_transaction_request_data(line_items, payments)
        items = []
        line_items.each do |item|
          items << build_item_hash(item)
        end if line_items

        tenders = []
        total = 0
        payments.each do |payment|
          tenders << build_payment_hash(payment)
          total += payment.amount
        end if payments

        {items: items, tenders: tenders, total: total}
      end

      def build_payment_hash(payment)
        {
          "IsStadisTender" => payment.class == StoredValuePayment,
          "StadisAuthorizationID" => (payment.class == StoredValuePayment) ? payment.authorization_id : "",
          "TenderTypeID" => (payment.class == StoredValuePayment) ? 1 : ((payment.class == CashPayment) ? 2 : 3),
          "TenderID" => (payment.class == StoredValuePayment) ? payment.code : '',
          "Amount" => payment.amount
        }
      end

      def build_item_hash(item)
        {
          "ItemID" => "#{item.item_id}",
          "Description" => item.item.name,
          "Dept" => "bypass",
          "Quantity" => item.count,
          "Price" => item.unit_price
        }
      end

      def make_request(action, message)
        return BypassStoredValue::MockResponse.new(message.values[0]) if @mock == true
        response = client.call(action,
          soap_action: soap_action(action),
          message: message)
        parsed_action = parse_action(action)
        BypassStoredValue::Response.new(response, parsed_action)
      end

      def parse_action(action)
        case action
        when "StadisAccountCharge" 
          "stadis_account_charge"
        when "PostTransaction"
          "stadis_post_transaction"
        when "ReverseStadisAccountCharge"
          "stadis_refund"
        when "ReloadGiftCard"
          "stadis_reload"
        else 
          "action_not_found"
        end
      end
    end
  end
end
