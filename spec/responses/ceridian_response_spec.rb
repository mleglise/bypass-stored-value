require 'spec_helper'

describe BypassStoredValue::CeridianResponse do

  it 'should respond to successful' do
    BypassStoredValue::CeridianResponse.any_instance.stub(:parse_action)
    response = BypassStoredValue::CeridianResponse.new("",:balance_inquiry)
    response.should respond_to(:successful?)
  end

  it 'should return successful if passed a valid response' do
    resp = double(hash: nori.parse(fixture("response/ceridian/balance_inquiry_response.xml")))
    response = BypassStoredValue::CeridianResponse.new(resp,:balance_inquiry)
    response.successful?.should be_true
    response.transaction_id.should_not be_nil
  end

  it 'should return false if not successful' do
    resp = double(hash: nori.parse(fixture("response/ceridian/invalid_response.xml")))
    response = BypassStoredValue::CeridianResponse.new(resp,:cancel)
    response.successful?.should be_false
    response.message.should eql('No Previous Authorizations')
  end
end