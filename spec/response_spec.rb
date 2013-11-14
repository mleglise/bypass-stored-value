require 'spec_helper'

describe BypassStoredValue::Response do
  it "should respond to successful?" do
    BypassStoredValue::Response.any_instance.stub(:parse)
    response_stub = double(body: {status_code: 0})
    response = BypassStoredValue::Response.new(response_stub, "stadis_account_charge")
    response.should respond_to(:successful?)
  end

  it "should call #parse when initialized" do
    response_stub = double(body: {status_code: 0})
    BypassStoredValue::Response.any_instance.should_receive(:parse)
    BypassStoredValue::Response.new(response_stub, "stadis_account_charge")
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
      BypassStoredValue::Response.any_instance.should_receive(:build_stadis_account_charge_response)
      BypassStoredValue::Response.new(@charge_response, "stadis_account_charge")
      BypassStoredValue::Response.any_instance.should_receive(:build_stadis_refund_response)
      BypassStoredValue::Response.new(@refund_response, "stadis_refund")
      BypassStoredValue::Response.any_instance.should_receive(:build_stadis_reload_response)
      BypassStoredValue::Response.new(@reload_response, "stadis_reload")
    end

    it "should raise an error if given action is not in ACTIONS constant" do
      expect{ BypassStoredValue::Response.new(@charge_response, "unavailable_action") }.to raise_error(BypassStoredValue::Exception::ActionNotFound)
    end

    it "should return an empty response if it receives a blank response from the server" do
      response_stub = double(body: nil)
      BypassStoredValue::Response.any_instance.should_receive(:empty_response)
      response = BypassStoredValue::Response.new(response_stub, "stadis_account_charge")
    end

    it "should return an unsuccessful response if it receives a blank response from the server" do
      response_stub = double(body: nil)
      response = BypassStoredValue::Response.new(response_stub, "stadis_account_charge")
      response.successful?.should == false
    end

    it "should return a stadis settle response" do
      response = BypassStoredValue::Response.new(nil, "stadis_settle")
      response.stadis_settle_response?.should == true
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
        response = BypassStoredValue::Response.new(response_stub, "stadis_reload")
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
      response = BypassStoredValue::Response.new(@successful_response_stub, "stadis_account_charge")
      response.successful?.should == true
    end

    it "should return false for status codes < 0" do
      response = BypassStoredValue::Response.new(@failed_response_stub, "stadis_account_charge")
      response.successful?.should == false
    end

    it "should return false for nil responses" do
      response = BypassStoredValue::Response.new(nil, "stadis_account_charge")
      response.successful?.should == false
    end
  end
end
