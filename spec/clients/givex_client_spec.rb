require 'spec_helper'

describe BypassStoredValue::Clients::GivexClient do

  before(:each) do
    #WebMock.allow_net_connect!
    @user = '29556'
    @password = '4866'
    @endpoint = 'dev-dataconnect.givex.com:50101'
    @client = BypassStoredValue::Clients::GivexClient.new(@user, @password)
  end
  after(:all) do
    WebMock.disable_net_connect!
  end

  describe 'stored value interface' do
    it 'should implement all public methods' do
      client = BypassStoredValue::Clients::GivexClient.new "me", "letmein"
      client.respond_to?(:settle).should be_true
      client.respond_to?(:refund).should be_true
      client.respond_to?(:authorize).should be_true
      client.respond_to?(:post_transaction).should be_true
    end

  end

  it 'can get balance' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/balance_check.json"))
    response = @client.check_balance '603628567891029892783'
    response.balance.should eql(100.0)
  end

  it 'can ping' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/null_response.json"))
    response = @client.ping
    response.result.should eql([])
  end

  it 'can activate a card' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/sucessful_transaction.json"))
    response = @client.issue('603628567891029892783', 500)
  end

  it 'can deduct $10' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/sucessful_transaction.json"))
    response = @client.settle('603628567891029892783', 10, false)
    response.successful?.should be_true
  end

  it 'can add funds to an account' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/sucessful_transaction.json"))
    response = @client.reload_account('603628835492000059280', 100)
    response.successful?.should be_true
  end

  it 'should be able to cancel a transaction' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/sucessful_transaction.json"))
    response = @client.refund('603628835492000059280', 'sometrans', 100)
    response.successful?.should be_true
    response.transaction_id.should eql('sometrans')
  end

  it 'returns a successful authorization' do
    response = @client.authorize('603628835492000059280', 100, false)
    response.successful?.should be_true
  end

  it 'tries the backup host if failure' do
    @client.stub(:client).and_raise("Timeout Error")
    expect(@client).to receive(:reversal).exactly(2).times
    @client.reload_account('603628835492000059280', 100)
  end

  it 'can pass in skus' do
    stub_request(:post, "https://#{@user}:#{@password}@#{@endpoint}/")
      .with(:body => /(...)/)
      .to_return(:body => fixture("response/givex/sucessful_transaction.json"))
    response = @client.settle('603628567891029892783', 10, false, [["124556", "19.99", "3"], ["124556", "19.99", "1"]])
    response.successful?.should be_true
  end


end