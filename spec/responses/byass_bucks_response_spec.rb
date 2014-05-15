require 'spec_helper'

describe BypassStoredValue::BypassBucksResponse do
  it 'should respond to successful' do
    BypassStoredValue::BypassBucksResponse.any_instance.stub(:parse_response)
    response = BypassStoredValue::BypassBucksResponse.new("",:get_balance)
    response.should respond_to(:successful?)
  end

  it 'should return successful if passed a valid check balance response' do
    resp = double(body: fixture("response/bypass_bucks/get_balance.json"))
    response = BypassStoredValue::BypassBucksResponse.new(resp, :get_balance)
    response.successful?.should be_true
  end

  it 'should return invalid if response is a failure' do
    resp = double(body: fixture("response/bypass_bucks/invalid_response.json"))
    response = BypassStoredValue::BypassBucksResponse.new(resp, 'dc_907')
    response.successful?.should be_false
    response.message.should eql('Error Something bad happened')
  end
end