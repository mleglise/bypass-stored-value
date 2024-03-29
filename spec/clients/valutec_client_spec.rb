require 'spec_helper'

describe BypassStoredValue::Clients::ValutecClient do
  before do
    args = {
      client_key: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
      terminal_id: '184012',
      server_id: '1234',
      identifier: '1000100',
      location_id: '307092'
    }
    @client = BypassStoredValue::Clients::ValutecClient.new(args)
  end

  it 'can create an instance' do
    @client.should be_an_instance_of BypassStoredValue::Clients::ValutecClient
  end

  describe '#basic_request_params' do
    it 'should return a hash containing general credentials used on all requests' do
      response = {
        ClientKey: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
        TerminalID: '184012',
        ProgramType: 'Gift',
        ServerID: '1234',
        Identifier: '1000100'
      }
      @client.send(:basic_request_params).should eql(response)
    end
  end

  describe 'actions' do
    describe '#check_balance' do
      it 'should call #transaction_card_balance with the appropriate message' do
        @client.should_receive(:transaction_card_balance).with({
          ClientKey: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
          TerminalID: '184012',
          ProgramType: 'Gift',
          CardNumber: '12345',
          ServerID: '1234',
          Identifier: '1000100'
        })
        @client.check_balance('12345')
      end
    end

    describe '#refund' do
      it 'should respond to 3 arguments' do #we submit amounts with refund requests for other stored value clients, so #refund needs to accept 3 args
        @client.stub(:transaction_add_value)
        expect { @client.refund('12345', '123456789', nil) }.not_to raise_error
      end

      it 'should call #reload_account' do
        @client.should_receive(:reload_account).with('12345', 5.00)
        @client.refund('12345', '123456789', 5.00)
      end
    end

    describe '#authorize' do
      context 'with no tip' do
        it 'should call #transaction_restaurant_sale with the appropriate message' do
          @client.should_receive(:transaction_restaurant_sale).with({
            ClientKey: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
            TerminalID: '184012',
            ProgramType: 'Gift',
            ServerID: '1234',
            Identifier: '1000100',
            CardNumber: '12345',
            Amount: 10.00,
            TipAmount: 0
          })
          @client.authorize('12345', 10.00, false)
        end
      end

      context 'with a tip' do
        it 'should call #transaction_restaurant_sale with the appropriate message' do
          @client.should_receive(:transaction_restaurant_sale).with({
            ClientKey: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
            TerminalID: '184012',
            ProgramType: 'Gift',
            ServerID: '1234',
            Identifier: '1000100',
            CardNumber: '12345',
            Amount: 0,
            TipAmount: 10.00
          })
          @client.authorize('12345', 10.00, true)
        end
      end
    end

    describe '#settle' do
      describe 'the returned ValutecResponse' do
        it 'should be successful? true' do
          BypassStoredValue::ValutecResponse.should_receive(:new).with(nil, 'settle', true)
          @client.settle('12345', 10.00, 5.00)
        end
      end
    end

    describe '#issue' do
      it 'should call #transaction_activate_card with the appropriate message' do
        @client.should_receive(:transaction_activate_card).with({
          ClientKey: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
          TerminalID: '184012',
          ProgramType: 'Gift',
          ServerID: '1234',
          Identifier: '1000100',
          CardNumber: '1234567',
          Amount: 10.00
        })
        @client.issue('1234567', 10.00)
      end
    end

    describe '#reload_account' do
      it 'should call #transaction_add_value with the appropriate message' do
        @client.should_receive(:transaction_add_value).with({
          ClientKey: '45c4ddcc-feb1-4cb1-99f0-1ba71d6d8f69',
          TerminalID: '184012',
          ProgramType: 'Gift',
          ServerID: '1234',
          Identifier: '1000100',
          CardNumber: '1234567',
          Amount: 10.00
        })
        @client.reload_account('1234567', 10.00)
      end
    end
  end
end