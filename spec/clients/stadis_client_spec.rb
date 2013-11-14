require 'spec_helper'

describe BypassStoredValue::Clients::StadisClient do
  context "An instance of the Stadis::Client class" do
    it "adds credentials in soap header" do
      Savon.should_receive(:client).with(endpoint: "http://localhost:3000/StadisWeb/StadisTransactions.asmx",
          namespace: "http://www.STADIS.com/",
          read_timeout: 5000,
          open_timeout: 360,
          element_form_default: :unqualified,
          namespace_identifier: nil,
          ssl_verify_mode: :none,
          env_namespace: :soap,
          soap_header: {
            SecurityCredentials: {
                UserID: "testuser",
                Password: "password"
            },
            attributes!:  {SecurityCredentials: {xmlns: "http://www.STADIS.com/"}}
          })
      client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000"})
    end

    context "#reload_card" do
      it "should call #make_request with ReloadGiftCard action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000", vendor_cashier: 1, register_id: 1})
        code = '1234'
        amount = 5.00
        request_params = {
          ReloadGiftCard: {
            CardID: code,
            Amount: amount}}
        client.should_receive(:make_request).with("ReloadGiftCard", request_params)
        client.reload_card(code, amount)
      end
    end

    context "#authorize" do
      it "should call #make_request with StadisAccountCharge action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000", vendor_cashier: 1, register_id: 1})
        code = "1234"
        amount = 2.00
        test_value = '123'
        BypassStoredValue::Clients::StadisClient.any_instance.stub(:rand).and_return(test_value)
        request_params = {
          ChargeInput: {
            ReferenceNumber: "byp_#{test_value}",
            RegisterID: 1,
            VendorCashier: 1,
            TransactionType: 1,
            TenderTypeID: 1,
            TenderID: code,
            Amount: amount}}
        response = double(body: {status_code: 0, amount_charged: 2.00, authorization_token: '12345'})
        client.should_receive(:make_request).with("StadisAccountCharge", request_params).and_return(response)
        client.authorize(code, amount)
      end
    end

    context "#make_request" do
      it "should return a MockResponse object if in mock mode" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000"})
        BypassStoredValue::MockResponse.should_receive(:new).with("THISISMYMESSAGE")
        client.send(:make_request, "THISISMYACTION", {message: "THISISMYMESSAGE"})
      end

      it "should call Savon#call using the given action and message if not in mock mode" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000"})
        response = double(body: {status_code: 0, stadis_authorization_code: '1234', charged_amount: 1.0})
        BypassStoredValue::Response.any_instance.stub(:parse)
        Savon::Client.any_instance.should_receive(:call).with("THISISMYACTION", soap_action: client.soap_action("THISISMYACTION"), message: {message: "THISISMYMESSAGE"}).and_return(response)
        client.send(:make_request, "THISISMYACTION", {message: "THISISMYMESSAGE"})
      end

      it "should return a successful MockResponse if given an amount > 0" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000"})
        test_value = '123'
        BypassStoredValue::Clients::StadisClient.any_instance.stub(:rand).and_return(test_value)
        message = {
          ChargeInput: {
            ReferenceNumber: "byp_#{test_value}",
            RegisterID: 1,
            VendorCashier: 1,
            TransactionType: 1,
            TenderTypeID: 1,
            TenderID: "1234",
            Amount: 2.00}}
        response = client.send(:make_request, "StadisAccountCharge", message)        
        response.successful?.should == true
        response.class.should == BypassStoredValue::MockResponse
      end

      it "should return a failed MockResponse if given an amount < 0" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000", register_id: 1, vendor_cashier: 1})
        test_value = '123'
        BypassStoredValue::Clients::StadisClient.any_instance.stub(:rand).and_return(test_value)
        message = {
          ChargeInput: {
            ReferenceNumber: "byp_#{test_value}",
            RegisterID: 1,
            VendorCashier: 1,
            TransactionType: 1,
            TenderTypeID: 1,
            TenderID: "1234",
            Amount: -2.00}}
        response = client.send(:make_request, "StadisAccountCharge", message)
        response.successful?.should == false
        response.class.should == BypassStoredValue::MockResponse
      end

      it "should return a BypassStoredValue::Response object" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000"})
        response = double(body: {status_code: 0})
        Savon::Client.any_instance.should_receive(:call).with("StadisAccountCharge", soap_action: client.soap_action("StadisAccountCharge"), message: {message: "THISISMYMESSAGE"}).and_return(response)
        BypassStoredValue::Response.any_instance.stub(:parse)
        response = client.send(:make_request, "StadisAccountCharge", {message: "THISISMYMESSAGE"})
        response.class.should == BypassStoredValue::Response
      end
    end

    context "#balance" do
      it "should call #make_request with StadisBalanceCheck action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000"})
        code = "1234"
        request_params = {
          StatusCheckInput: {
            TransactionType: 3,
            TenderTypeID: 1,
            TenderID: code,
            Amount: 0}}
        client.should_receive(:make_request).with("StadisBalanceCheck", request_params)
        client.balance(code)
      end
    end

    context "#refund" do
      it "should call #make_request with ReverseStadisAccountCharge action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000", register_id: 1, vendor_cashier: 1})
        code = "1234"
        authorization_id = 1
        amount = 2.00
        request_params = {
          ReverseChargeInput: {
            ReferenceNumber: authorization_id,
            RegisterID: 1,
            VendorCashier: 1,
            TransactionType: 2,
            TenderTypeID: 1,
            TenderID: code,
            Amount: amount}}
        client.should_receive(:make_request).with("ReverseStadisAccountCharge", request_params)
        client.refund(code, authorization_id, amount)
      end
    end

    context "#build_item_hash" do
      it "should build a request-worthy hash from the given item hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000", register_id: 1, vendor_cashier: 1})
        item_hash = {item_id: 1, item_name: 'Item1', count: 2, unit_price: 5.0}
        hash = client.send(:build_item_hash, item_hash)
        hash[:ItemID].should == '1'
        hash[:Description].should == 'Item1'
        hash[:Quantity].should == 2
        hash[:Price].should == 5.0
      end
    end

    context "#build_payment_hash" do
      before do
        @client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000", register_id: 1, vendor_cashier: 1})
      end

      it "should build a request-worthy hash from the given stadis payment hash" do
        payment_hash = {stadis: true, transaction_id: 1, code: '1234', amount: 5.0}
        hash = @client.send(:build_payment_hash, payment_hash)
        hash[:IsStadisTender].should == true
        hash[:StadisAuthorizationID].should == 1
        hash[:TenderTypeID].should == 1
        hash[:TenderID].should == '1234'
        hash[:Amount].should == 5.0
      end

      it "should build a hash with appropriate contents for a cash payment" do
        payment_hash = {stadis: false, cash: true, amount: 5.0}
        hash = @client.send(:build_payment_hash, payment_hash)
        hash[:IsStadisTender].should == false
        hash[:StadisAuthorizationID].should == ''
        hash[:TenderTypeID].should == 2
        hash[:TenderID].should == ''
        hash[:Amount].should == 5.0
      end

      it "should build a hash with appropriate contents for any other type of payment" do
        payment_hash = {stadis: false, cash: false, amount: 5.0}
        hash = @client.send(:build_payment_hash, payment_hash)
        hash[:IsStadisTender].should == false
        hash[:StadisAuthorizationID].should == ''
        hash[:TenderTypeID].should == 3
        hash[:TenderID].should == ''
        hash[:Amount].should == 5.0
      end
    end

    context "#post_transaction" do
      before do
        @client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000", register_id: 1, vendor_cashier: 1})
        @line_items = [{
          item_id: 1,
          item_name: "NAME",
          count: 1,
          unit_price: 2.00
        }]
        @payments = [{
          stadis: true,
          transaction_id: 1,
          code: '1234',
          amount: 2.00
        }]
      end

      it "should call #set_up_transaction_request_data" do
        @client.should_receive(:set_up_transaction_request_data).with(@line_items, @payments).and_return({items: @line_items, tenders: @payments, total: 5.0})
        @client.post_transaction(@line_items, @payments)
      end
    end
  end
end
