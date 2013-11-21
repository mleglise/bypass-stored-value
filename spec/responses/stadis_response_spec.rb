require 'spec_helper'

describe BypassStoredValue::StadisResponse do
  it "should respond to successful?" do
    BypassStoredValue::StadisResponse.any_instance.stub(:parse)
    response_stub = double(body: {status_code: 0})
    response = BypassStoredValue::StadisResponse.new(response_stub, "stadis_account_charge")
    response.should respond_to(:successful?)
  end

  it "should call #parse when initialized" do
    response_stub = double(body: {status_code: 0})
    BypassStoredValue::StadisResponse.any_instance.should_receive(:parse)
    BypassStoredValue::StadisResponse.new(response_stub, "stadis_account_charge")
  end

  context "#transaction_id" do
    it "should return the result's authentication token" do
      refund_response = double(body: {
        reverse_stadis_account_charge_response: {
          reverse_stadis_account_charge_result: {
            return_message: {
              return_code: 0},
            stadis_reply: {
              stadis_authorization_id: '1234',
              charged_amount: -1.00,
              remaining_amount: 1.00}}}})
      response = BypassStoredValue::StadisResponse.new(refund_response, "stadis_refund")
      response.transaction_id.should == "1234"
    end
  end

  context "refunded_amount" do
    it "should return the result charged amount if the action is stadis_refund" do
      refund_response = double(body: {
        reverse_stadis_account_charge_response: {
          reverse_stadis_account_charge_result: {
            return_message: {
              return_code: 0},
            stadis_reply: {
              stadis_authorization_id: '1234',
              charged_amount: -1.00,
              remaining_amount: 1.00}}}})
      response = BypassStoredValue::StadisResponse.new(refund_response, "stadis_refund")
      response.refunded_amount.should == -1.00
    end
  end

  context "#parse" do
    before do
      @charge_response = double(body: {
        stadis_account_charge_response: {
          stadis_account_charge_result: {
            return_message: {
              return_code: 0},
            stadis_reply: {
              stadis_authorization_id: '1234',
              charged_amount: 1.00,
              remaining_amount: 1.00}}}})
      @refund_response = double(body: {
        reverse_stadis_account_charge_response: {
          reverse_stadis_account_charge_result: {
            return_message: {
              return_code: 0},
            stadis_reply: {
              stadis_authorization_id: '1234',
              charged_amount: 1.00,
              remaining_amount: 1.00}}}})
      @reload_response = double(body: {
        reload_gift_card_response: {
          reload_gift_card_result: {
            return_message: {
              return_code: 0},
            stadis_reply: {
              stadis_authentication_id: '1234',
              charged_amount: 1.00,
              remaining_amount: 1.00}}}})
    end

    it "should call appropriate build ___ response method" do
      BypassStoredValue::StadisResponse.any_instance.should_receive(:build_stadis_account_charge_response)
      BypassStoredValue::StadisResponse.new(@charge_response, "stadis_account_charge")
      BypassStoredValue::StadisResponse.any_instance.should_receive(:build_stadis_refund_response)
      BypassStoredValue::StadisResponse.new(@refund_response, "stadis_refund")
      BypassStoredValue::StadisResponse.any_instance.should_receive(:build_stadis_reload_response)
      BypassStoredValue::StadisResponse.new(@reload_response, "stadis_reload")
    end

    it "should raise an error if given action is not in ACTIONS constant" do
      expect{ BypassStoredValue::StadisResponse.new(@charge_response, "unavailable_action") }.to raise_error(BypassStoredValue::Exception::ActionNotFound)
    end

    it "should return a successful response for stadis settle action" do
      response = BypassStoredValue::StadisResponse.new(nil, "stadis_settle")
      response.successful?.should == true
    end
  end

  context "#build_stadis_reload_response" do
    it "should build an appropriate hash based on the given response" do
      response_stub = double(body: {
        :reload_gift_card_response => {
          :reload_gift_card_result => {
            :return_message => {
              :return_code => "-2",
              :message => "Ticket not found or event not open."},
            :stadis_reply => {
              :reference_number => "GCLOAD",
              :stadis_authorization_id => nil,
              :tender_status_code => "0",
              :tender_status_message => nil,
              :account_status_code => "2",
              :account_status_message => "Customer status unknown.;;0;0;0;0;0;;;",
              :charged_amount => "0",
              :remaining_amount => "0"}},
        :@xmlns => "http://www.STADIS.com/"}})
        response = BypassStoredValue::StadisResponse.new(response_stub, "stadis_reload")
        response.result.should == {status_code: -2, authentication_token: nil, charged_amount: 0.0, remaining_balance: 0.0}
    end

  end

  context "#successful?" do
    before do
      @successful_response_stub = double(body: {
        stadis_account_charge_response: {
          stadis_account_charge_result: {
            return_message: {
              return_code: "0"},
            stadis_reply: {
              stadis_authorization_id: 'AUTH_ID',
              charged_amount: 2.00,
              remaining_amount: 5.00}}}})
      @failed_response_stub = double(body: {
        stadis_account_charge_response: {
          stadis_account_charge_result: {
            return_message: {
              return_code: "-1"},
            stadis_reply: {
              stadis_authorization_id: 'AUTH_ID',
              charged_amount: 0.00,
              remaining_amount: 0.00}}}})
    end

    it "should return true for status codes >= 0" do
      response = BypassStoredValue::StadisResponse.new(@successful_response_stub, "stadis_account_charge")
      response.successful?.should == true
    end

    it "should return false for status codes < 0" do
      response = BypassStoredValue::StadisResponse.new(@failed_response_stub, "stadis_account_charge")
      response.successful?.should == false
    end
  end
end
