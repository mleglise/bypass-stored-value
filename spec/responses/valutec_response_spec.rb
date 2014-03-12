require 'spec_helper'

describe BypassStoredValue::ValutecResponse do
  describe 'failed requests' do
    subject do
      response = nori.parse(fixture("response/valutec/invalid_transaction_restaurant_sale_response.xml"))
      resp = double(body: response[:envelope][:body])
      BypassStoredValue::ValutecResponse.new(resp, :transaction_restaurant_sale)
    end

    it 'returns false for failed requests' do
      subject.successful?.should be_false
    end

    it 'returns the error messages' do
      subject.message.should eq 'Invalid Client Key'
    end

    it 'should return a successful? true response for a settle' do
      resp = BypassStoredValue::ValutecResponse.new(nil, 'settle', true)
      resp.successful?.should eq true
    end

    describe '#parse' do
      it 'should return an error if the action given is not in the ACTIONS constant' do
        subject.action = 'some_crazy_action'
        ->{ subject.parse }.should raise_error BypassStoredValue::Exception::ActionNotFound
      end

      it 'should call the appropriate build_ACTION_response method based on the action given' do
        subject.should_receive(:parse_transaction_restaurant_sale_response)
        subject.parse
      end

      it 'should return the result set by the build_ACTION_response method invoked' do
        result = {
          authentication_token: '12345',
          charged_amount: '2.00',
          remaining_balance: '10.00'
        }

        subject.response = {
          transaction_restaurant_sale_response: {
            transaction_restaurant_sale_result: {
              authorization_code: '12345',
              card_amount_used: '2.00',
              balance: '10.00'
            }
          }
        }

        subject.parse.should eq result
      end
    end
  end
end
