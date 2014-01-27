require 'spec_helper'

describe BypassStoredValue::GivexResponse do
  it 'should respond to successful' do
    BypassStoredValue::GivexResponse.any_instance.stub(:parse_response)
    response = BypassStoredValue::GivexResponse.new("",'dc_909')
    response.should respond_to(:successful?)
  end

  it 'should return successful if passed a valid check balance response' do
    resp = double(body: fixture("response/givex/balance_check.json"))
    response = BypassStoredValue::GivexResponse.new(resp, 'dc_909')
    response.successful?.should be_true
    response.transaction_id.should eql 'sometrans'
  end

  it 'should return invalid if response is a failure' do
    resp = double(body: fixture("response/givex/invalid_response.json"))
    response = BypassStoredValue::GivexResponse.new(resp, 'dc_907')
    response.successful?.should be_false
    response.transaction_id.should eql 'sometrans'
    response.message.should eql('Error 19 : Operation not permitted')
  end
end