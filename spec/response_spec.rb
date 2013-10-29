require 'spec_helper'

describe BypassStoredValue::Response do
  it "should respond to successful?" do
    BypassStoredValue::Response.any_instance.stub(:parse)
    response_stub = double(body: {status_code: 0})
    response = BypassStoredValue::Response.new(response_stub, "stadis_charge")
    response.should respond_to(:successful?)
  end

  it "should call #parse when initialized" do
    response_stub = double(body: {status_code: 0})
    BypassStoredValue::Response.any_instance.should_receive(:parse)
    BypassStoredValue::Response.new(response_stub, "stadis_charge")
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
      response = BypassStoredValue::Response.new(response_stub, "stadis_charge")
    end

    it "should return an unsuccessful response if it receives a blank response from the server" do
      response_stub = double(body: nil)
      response = BypassStoredValue::Response.new(response_stub, "stadis_charge")
      response.successful?.should == false
    end
  end

  context "#successful?" do
    before do
      @response_stub = double(body: {})
    end

    it "should return true for status codes >= 0" do
      BypassStoredValue::Response.any_instance.stub(:parse)
      response = BypassStoredValue::Response.new(@response_stub, "stadis_charge")
      response.result[:status_code] = 0
      response.successful?.should == true
      response = BypassStoredValue::Response.new(@response_stub, "stadis_charge")
      response.result[:status_code] = 1
      response.successful?.should == true
    end

    it "should return false for status codes < 0" do
      BypassStoredValue::Response.any_instance.stub(:parse)
      response = BypassStoredValue::Response.new(@response_stub, "stadis_charge")
      response.result[:status_code] = -1
      response.successful?.should == false
    end

    it "should return false for nil responses" do
      response = BypassStoredValue::Response.new(nil, "stadis_charge")
      response.successful?.should == false
    end
  end
end
