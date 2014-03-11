require 'spec_helper'

describe BypassStoredValue::Clients::CeridianClient do
  it 'Can create an instance' do
    BypassStoredValue::Clients::CeridianClient.new("user", "pass").should be_an_instance_of BypassStoredValue::Clients::CeridianClient
  end

  describe 'stored value interface' do
    subject { BypassStoredValue::Clients::CeridianClient.new "me", "letmein" }
    it { should respond_to(:settle) }
    it { should respond_to(:refund) }
    it { should respond_to(:authorize) }
    it { should respond_to(:post_transaction) }
  end

  describe "actions" do
    it 'can print actions' do
      BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
    end

    it 'can handle balance inquiry' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/balance_inquiry_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "me", "pass"
      response = client.balance_inquiry('6003922300594628')
      response.hash[:envelope][:body][:balance_inquiry_response][:balance_inquiry_return][:balance_amount][:amount].should eql('100.0')

    end

    it 'can add funds to a new card' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/issue_gift_card_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "me", "pass"
      response = client.issue_gift_card('6006492606749900007', 100.00, Time.now.strftime('%H%M%S'))
      response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:approved_amount][:amount].should eql('75.0')
      response.hash[:envelope][:body][:issue_gift_card_response][:issue_gift_card_return][:stan]
    end

    it 'can redeem funds' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/redeem_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      response = client.redeem('6006492606749903795', 5.00)
      response.hash[:envelope][:body][:redemption_response][:redemption_return][:approved_amount][:amount].should eql('5.0')
    end

    it 'can reload funds' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/reload_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "me", "pass"
      response = client.card_recharge('6006492606749903811', 5.00)
      response.hash[:envelope][:body][:card_recharge_response][:card_recharge_return][:approved_amount][:amount].should eql('5.0')
    end

    it 'can add a tip' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/tip_response.xml"))
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      response = client.tip('6006492606749903811', 5.00)
      response.hash[:envelope][:body][:tip_response][:tip_return][:approved_amount][:amount].should eql('5.0')
    end

    it 'can redeem and cancel it' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/redeem_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
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
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
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

      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
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

      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      client.balance_inquiry('6006492606749903720')
    end

    xit 'can pre-auth a card and then settle the amount' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      response = client.pre_auth('6006492606749903720', 5.0)
      response.hash[:envelope][:body][:pre_auth_response][:pre_auth_return][:approved_amount][:amount].should eql('5.0')
      stan = response.hash[:envelope][:body][:pre_auth_response][:pre_auth_return][:stan]

      response = client.pre_auth_complete('6006492606749903720', 5.0, stan)
      response.hash[:envelope][:body][:pre_auth_complete_response][:pre_auth_complete_return][:return_code][:return_code].should eql('01')
    end
  end

  describe "Failed transactions" do
    it 'should send a reversal after a timeout' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/invalid_issue_gift_card_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"

      expect(client).to receive(:reversal).exactly(3).times
      client.issue_gift_card('6006492606749903787', 75.00, Time.now.strftime('%H%M%S'))

    end

    it 'should retry a request if a timeout occurs' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      client.stub(:client).and_raise("Timeout Error")
      expect(client).to receive(:reversal).exactly(3).times
      client.issue_gift_card('6006492606749903787', 75.00, Time.now.strftime('%H%M%S'))
    end

    it 'should return a failure response if a failure occurs' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      client.stub(:client).and_raise("Timeout Error")
      response = client.issue_gift_card('6006492606749903787', 75.00, Time.now.strftime('%H%M%S'))
      expect(response).to be_an_instance_of(BypassStoredValue::FailedResponse)
    end

    xit 'should handle failed login' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      response = client.balance_inquiry('6006492606749903753')
      expect(response).to be_an_instance_of(BypassStoredValue::FailedResponse)
      response.message.should eql('Trouble taking to service.')
    end

    it 'should send a cancel 3 times if it fails' do
      stub_request(:post, "https://webservices-cert.storedvalue.com/svsxml/services/SVSXMLWay")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/ceridian/invalid_issue_gift_card_response.xml"))

      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      expect(client).to receive(:make_request).exactly(3).times
      client.cancel('6006492606749903787', 75.00, Time.now.strftime('%H%M%S'))

    end

    it 'should return an object that response to successful for authorize' do
      client = BypassStoredValue::Clients::CeridianClient.new "me", "letmein"
      resp = client.authorize("asdfsaf", 500, 0)
      resp.successful?.should be_true
    end
  end
end
