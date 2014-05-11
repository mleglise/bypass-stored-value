require 'spec_helper'

describe BypassStoredValue::Clients::BypassBucksClient do

  before(:each) do
    #WebMock.allow_net_connect!
    @user = 'bypass'
    @password = 'bypass'
    @endpoint = 'bypassbucks-integration.bypasslane.com'
    @client = BypassStoredValue::Clients::BypassBucksClient.new(@user, @password)
    @card_number = "2972774077005123"
  end
  after(:all) do
    WebMock.disable_net_connect!
  end

  describe 'stored value interface' do
    it 'should implement all public methods' do
      client = BypassStoredValue::Clients::BypassBucksClient.new "me", "letmein"
      client.respond_to?(:settle).should be_true
      client.respond_to?(:refund).should be_true
      client.respond_to?(:authorize).should be_true
      client.respond_to?(:post_transaction).should be_true
    end

  end

  it 'can get balance' do

    stub_request(:get, "https://#{@user}:#{@password}@#{@endpoint}/cards/#{@card_number}/get_balance")
    .with(:body => /(...)/)
    .to_return(:body => fixture("response/bypass_bucks/get_balance.json"))
    response = @client.check_balance '2972774077005123'
    response.balance.should eql(100)
  end

  it 'can activate a card' do
    stub_request(:put, "https://#{@user}:#{@password}@#{@endpoint}/cards/#{@card_number}/activate")
    .with(:body => /(...)/)
    .to_return(:body => fixture("response/bypass_bucks/show_card.json"))
    response = @client.activate(@card_number, 195)
    response.balance.should eql(195)
  end

  it 'can deduct $10' do
    stub_request(:put, "https://#{@user}:#{@password}@#{@endpoint}/cards/#{@card_number}/redeem")
    .with(:body => /(...)/)
    .to_return(:body => fixture("response/bypass_bucks/show_card.json"))
    response = @client.redeem(@card_number, 100, false)
    response.successful?.should be_true
  end

  it 'can add funds to an account' do
    stub_request(:put, "https://#{@user}:#{@password}@#{@endpoint}/cards/#{@card_number}/increment")
    .with(:body => /(...)/)
    .to_return(:body => fixture("response/bypass_bucks/show_card.json"))
    response = @client.increment(@card_number, 1000)
    response.successful?.should be_true
  end

end