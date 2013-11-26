require 'spec_helper'

describe BypassStoredValue::Clients::GivexClient do

  before(:all) do
    WebMock.allow_net_connect!
  end
  after(:all) do
    WebMock.disable_net_connect!
  end

  it 'can get balance' do
    pending()
    client = BypassStoredValue::Clients::GivexClient.new('29106', '1193')
    resp = client.get_balance '603628835492000059280'
  end

end