require 'spec_helper'

describe BypassStoredValue::Clients::CeridianClient do
  before do

  end

  it 'Can create an instance' do
    BypassStoredValue::Clients::CeridianClient.new("user", "pass").should be_an_instance_of BypassStoredValue::Clients::CeridianClient
  end

  describe "actions" do
    it 'can print actions' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
    end
    it 'can handle balance inquiry' do
      #stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      #.with(:body => /(...)/)
      #.to_return(:body => fixture("response/balance_inquiry.xml"))

      #client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      #response = client.get_balance
    end

    #it 'can add funds to a new card' do
    #  WebMock.allow_net_connect!
    #  client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
    #  puts response = client.issue_gift_card('6006492606749903811', 100.00, 1234, (Time.now + 365*24*60*60).strftime('%Y-%m-%dT00:00:00'))
    #end

    #it 'can check balance' do
    #  client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
    #  response = client.get_balance('6006492606749903811')
    #  puts response.hash
    #end
  end
end
