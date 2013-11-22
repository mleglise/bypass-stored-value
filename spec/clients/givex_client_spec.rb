require 'spec_helper'

describe BypassStoredValue::Clients::GivexClient do
  it 'has operations' do
    client = BypassStoredValue::Clients::GivexClient.new('29106', '1193')
    client.get_operations.should_not be_empty
  end

end