require 'spec_helper'

describe BypassStoredValue::Clients::CeridianClient do
  before do

  end

  it 'Can create an instance' do
    BypassStoredValue::Clients::CeridianClient.new("user", "pass").should be_an_instance_of BypassStoredValue::Clients::CeridianClient
  end

  describe 'stored value interface' do
    it 'should implement all public methods' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      client.respond_to?(:settle).should be_true
      client.respond_to?(:deduct).should be_true
      client.respond_to?(:authorize).should be_true
      client.respond_to?(:post_transaction).should be_true
    end

  end

  describe "actions" do
    before(:all) do
      #WebMock.allow_net_connect!
    end
    after(:all) do
      #WebMock.disable_net_connect!
    end

    it 'can print actions' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
    end
    it 'can handle balance inquiry' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/balance_inquiry_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.balance_inquiry('6006492606749903753')
      response.hash[:envelope][:body][:balance_inquiry_response][:balance_inquiry_return][:balance_amount][:amount].should eql('100.0')
    end

    it 'can add funds to a new card' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/issue_gift_card_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.issue_gift_card('6006492606749903811', 75.00, Time.now.strftime('%H%M%S'))
      response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:approved_amount][:amount].should eql('75.0')
    end

    it 'can redeem funds' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/redeem_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.redeem('6006492606749903811', 5.00)
      response.hash[:envelope][:body][:redemption_response][:redemption_return][:approved_amount][:amount].should eql('5.0')
    end

    it 'can reload funds' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/reload_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.reload('6006492606749903811', 5.00)
      response.hash[:envelope][:body][:reload_response][:reload_return][:approved_amount][:amount].should eql('5.0')

    end

    it 'can add a tip' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/tip_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.tip('6006492606749903811', 5.00)
      response.hash[:envelope][:body][:tip_response][:tip_return][:approved_amount][:amount].should eql('5.0')
    end

    it 'can redeem and cancel it' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/redeem_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.redeem('6006492606749903753', 5.00)
      response.hash[:envelope][:body][:redemption_response][:redemption_return][:approved_amount][:amount].should eql('5.0')
      stan = response.hash[:envelope][:body][:redemption_response][:redemption_return][:stan]

      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/cancel_response.xml"))

      response = client.cancel('6006492606749903753', 5.00, stan)
      response.hash[:envelope][:body][:cancel_response][:cancel_return][:approved_amount][:amount].should eql('5.0')
    end

    it 'can issue and void' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/issue_gift_card_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.issue_gift_card('6006492606749903738', 75.00, Time.now.strftime('%H%M%S'))
      response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:approved_amount][:amount].should eql('75.0')
      stan = response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:stan]

      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/cancel_issue_response.xml"))

      response = client.cancel('6006492606749903738', 75.00, stan)

      response.hash[:envelope][:body][:cancel_response][:cancel_return][:approved_amount][:amount].should eql('75.0')
      response.hash[:envelope][:body][:cancel_response][:cancel_return][:balance_amount][:amount].should eql('0.0')
    end

    it 'can create a tip payment and void it' do
      #WebMock.allow_net_connect!
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/balance_inquiry_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.balance_inquiry('6006492606749903753')
      balance = response.hash[:envelope][:body][:balance_inquiry_response][:balance_inquiry_return][:balance_amount][:amount]

      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/tip_response.xml"))

      response = client.tip('6006492606749903753', 5.00)
      response.hash[:envelope][:body][:tip_response][:tip_return][:approved_amount][:amount].should eql('5.0')
      stan = response.hash[:envelope][:body][:tip_response][:tip_return][:stan]

      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/cancel_response.xml"))

      response = client.cancel('6006492606749903753', 5.00, stan)
      response.hash[:envelope][:body][:cancel_response][:cancel_return][:approved_amount][:amount].should eql('5.0')
      response.hash[:envelope][:body][:cancel_response][:cancel_return][:balance_amount][:amount].should eql(balance)
      #WebMock.disable_net_connect!
    end
    it 'can clear a registered card' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/balance_inquiry_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.balance_inquiry('6006492606749903720')
    end

    xit 'can pre-auth a card and then settle the amount' do
      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"
      response = client.pre_auth('6006492606749903720', 5.0)
      response.hash[:envelope][:body][:pre_auth_response][:pre_auth_return][:approved_amount][:amount].should eql('5.0')
      stan = response.hash[:envelope][:body][:pre_auth_response][:pre_auth_return][:stan]

      response = client.pre_auth_complete('6006492606749903720', 5.0, stan)
      response.hash[:envelope][:body][:pre_auth_complete_response][:pre_auth_complete_return][:return_code][:return_code].should eql('01')
    end
  end

  describe "Failed transactions" do
    xit 'should send a reversal after a timeout' do

      client = BypassStoredValue::Clients::CeridianClient.new "extpalaceuat", "Pl594Ut13"

      response = client.issue_gift_card('6006492606749903787', 75.00, Time.now.strftime('%H%M%S'))
      response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:approved_amount][:amount].should eql('75.0')
      stan = response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:stan]

      response = client.reversal('6006492606749903787', 75.00, stan)
      response.hash[:envelope][:body][:reversal_response][:reversal_return][:return_code][:return_code].should eql('01')

    end
  end
end
