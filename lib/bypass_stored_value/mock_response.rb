module BypassStoredValue
  class MockResponse < BypassStoredValue::Response
    def initialize(response)
      @response = response
      generate_successful_response
      generate_failed_response if response['Amount'] < 0
    end

    def generate_successful_response
      @result = {
        status_code: 0,
        amount_charged: response[:amount],
        authentication_token: 'STOREDVALUEMOCK'}
    end

    def generate_failed_response
      @result = {
        status_code: -1,
        failed_amount: response[:amount],
        authentication_token: 'STOREDVALUEMOCK'}
    end
  end
end
