require 'spec_helper'

describe BypassStoredValue::ValutecResponse do
  describe 'failed requests' do
    subject do
      resp = double(body: nori.parse(fixture("response/valutec/invalid_transaction_restaurant_sale_response.xml")))
      BypassStoredValue::ValutecResponse.new(resp, :transaction_restaurant_sale)
    end

    it 'returns false for failed requests' do
      subject.successful?.should be_false
    end

    it 'returns the error messages' do
      subject.message.should eq 'Invalid Client Key'
    end
  end
end
