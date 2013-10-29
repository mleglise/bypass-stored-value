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
            "SecurityCredentials" => {
                "UserID" => "testuser",
                "Password" => "password"
            },
            :attributes! => {"SecurityCredentials" => {"xmlns" => "http://www.STADIS.com/"}}
          })
      client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000"})
    end

    context "#reload_card" do
      it "should call #make_request with ReloadGiftCard action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000", vendor_cashier: 1, register_id: 1})
        code = '1234'
        amount = 5.00
        request_params = {
          "ReloadGiftCard" => {
            "CardID" => code,
            "Amount" => amount}}
        client.should_receive(:make_request).with("ReloadGiftCard", request_params)
        client.reload_card(code, amount)
      end
    end

    context "#account_charge" do
      it "should call #make_request with StadisAccountCharge action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000", vendor_cashier: 1, register_id: 1})
        code = "1234"
        amount = 2.00
        test_value = '123'
        BypassStoredValue::Clients::StadisClient.any_instance.stub(:rand).and_return(test_value)
        request_params = {
          "ChargeInput" => {
            "ReferenceNumber" => "byp_#{test_value}",
            "RegisterID" => 1,
            "VendorCashier" => 1,
            "TransactionType" => 1,
            "TenderTypeID" => 1,
            "TenderID" => code,
            "Amount" => amount}}
        response = double(body: {status_code: 0, amount_charged: 2.00, authorization_token: '12345'})
        client.should_receive(:make_request).with("StadisAccountCharge", request_params).and_return(response)
        client.account_charge(code, amount)
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
        Savon::Client.any_instance.should_receive(:call).with("THISISMYACTION", soap_action: client.soap_action("THISISMYACTION"), message: {message: "THISISMYMESSAGE"}).and_return(response)
        client.send(:make_request, "THISISMYACTION", {message: "THISISMYMESSAGE"})
      end

      it "should return a successful MockResponse if given an amount > 0" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000"})
        test_value = '123'
        BypassStoredValue::Clients::StadisClient.any_instance.stub(:rand).and_return(test_value)
        message = {
          "ChargeInput" => {
            "ReferenceNumber" => "byp_#{test_value}",
            "RegisterID" => 1,
            "VendorCashier" => 1,
            "TransactionType" => 1,
            "TenderTypeID" => 1,
            "TenderID" => "1234",
            "Amount" => 2.00}}
        response = client.send(:make_request, "StadisAccountCharge", message)        
        response.successful?.should == true
        response.class.should == BypassStoredValue::MockResponse
      end

      it "should return a failed MockResponse if given an amount < 0" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000", register_id: 1, vendor_cashier: 1})
        test_value = '123'
        BypassStoredValue::Clients::StadisClient.any_instance.stub(:rand).and_return(test_value)
        message = {
          "ChargeInput" => {
            "ReferenceNumber" => "byp_#{test_value}",
            "RegisterID" => 1,
            "VendorCashier" => 1,
            "TransactionType" => 1,
            "TenderTypeID" => 1,
            "TenderID" => "1234",
            "Amount" => -2.00}}
        response = client.send(:make_request, "StadisAccountCharge", message)
        response.successful?.should == false
        response.class.should == BypassStoredValue::MockResponse
      end

      it "should return a BypassStoredValue::Response object" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {protocol: "http", host: "localhost", port: "3000"})
        response = double(body: {status_code: 0})
        Savon::Client.any_instance.should_receive(:call).with("THISISMYACTION", soap_action: client.soap_action("THISISMYACTION"), message: {message: "THISISMYMESSAGE"}).and_return(response)
        response = client.send(:make_request, "THISISMYACTION", {message: "THISISMYMESSAGE"})
        response.class.should == BypassStoredValue::Response
      end
    end

    context "#balance" do
      it "should call #make_request with StadisBalanceCheck action and properly formatted message hash" do
        client = BypassStoredValue::Clients::StadisClient.new("testuser", "password", {mock: true, protocol: "http", host: "localhost", port: "3000"})
        code = "1234"
        request_params = {
          "StatusCheckInput" => {
            "TransactionType" => 3,
            "TenderTypeID" => 1,
            "TenderID" => code,
            "Amount" => 0}}
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
          "ReverseChargeInput" => {
            "ReferenceNumber" => authorization_id,
            "RegisterID" => 1,
            "VendorCashier" => 1,
            "TransactionType" => 2,
            "TenderTypeID" => 1,
            "TenderID" => code,
            "Amount" => amount}}
        client.should_receive(:make_request).with("ReverseStadisAccountCharge", request_params)
        client.refund(code, authorization_id, amount)
      end
    end
  end
end
