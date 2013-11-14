require 'spec_helper'

describe BypassStoredValue::Clients::CeridianClient do
  before do

  end

  it 'Can create an instance' do
    BypassStoredValue::Clients::CeridianClient.new("user", "pass").should be_an_instance_of BypassStoredValue::Clients::CeridianClient
  end

  describe "actions" do
    it 'can handle balance inquiry' do
      #stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      #.with(:body => /(...)/)
      #.to_return(:body => fixture("response/balance_inquiry.xml"))

      #client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      #response = client.get_balance
    end
  end
end
