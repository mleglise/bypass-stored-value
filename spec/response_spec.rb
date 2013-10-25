require 'spec_helper'

describe BypassStoredValue::Response do
  it "should respond to successful?" do
    response_stub = double(body: {status_code: 0})
    response = BypassStoredValue::Response.new(response_stub)
    response.should respond_to(:successful?)
  end

  it "should call #parse when initialized" do
    response_stub = double(body: {status_code: 0})
    BypassStoredValue::Response.any_instance.should_receive(:parse)
    BypassStoredValue::Response.new(response_stub)
  end

  context "#parse" do
    it "should set status code, authentication token, and charged amount keys on the result hash for a stadis request" do
      response_stub = double(body: {status_code: 0, stadis_authorization_id: '1234', charged_amount: 5.00})
      response = BypassStoredValue::Response.new(response_stub)
      response.result[:status_code].should == 0
      response.result[:authentication_token].should == '1234'
      response.result[:charged_amount].should == 5.00
    end
  end

  context "#successful?" do
    it "should return true for status codes >= 0" do
      response_stub = double(body: {status_code: 0})
      response = BypassStoredValue::Response.new(response_stub)
      response.successful?.should == true
      response_stub = double(body: {status_code: 1})
      response = BypassStoredValue::Response.new(response_stub)
      response.successful?.should == true
    end

    it "should return false for status codes < 0" do
      response_stub = double(body: {status_code: -1})
      response = BypassStoredValue::Response.new(response_stub)
      response.successful?.should == false
    end

    it "should return false for nil responses" do
      response = BypassStoredValue::Response.new(nil)
      response.successful?.should == false
    end
  end
end
