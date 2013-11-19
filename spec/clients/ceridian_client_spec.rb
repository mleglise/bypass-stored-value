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
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/balance_inquiry.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      response = client.get_balance('6006492606749903811')
      response.hash[:envelope][:body][:balance_inquiry_response][:balance_inquiry_return][:balance_amount][:amount].should eql('100.0')
    end

    it 'can add funds to a new card' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/issue_gift_card_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.issue_gift_card('6006492606749903811', 100.00)
      response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:approved_amount][:amount].should eql('100.0')
    end

    it 'can redeem funds' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/redeem_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.redeem('6006492606749903811', 5.00)
      response.hash[:envelope][:body][:redemption_response][:redemption_return][:approved_amount][:amount].should eql('5.0')
    end
  end
end
