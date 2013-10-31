module BypassStoredValue
  class MockResponse < BypassStoredValue::Response
    attr_reader :request

    def initialize(request)
      @request = request
      generate_successful_response
      generate_failed_response if failed_response_needed?
    end

    private

    def failed_response_needed?
      (request[:Amount] and request[:Amount] < 0) || (request[:Total] and request[:Total] < 0)
    end

    def generate_successful_response
      @result = {
        status_code: 0,
        amount_charged: request[:Amount],
        authentication_token: 'STOREDVALUEMOCK'}
    end

    def generate_failed_response
      @result = {
        status_code: -1,
        failed_amount: request[:Amount],
        authentication_token: 'STOREDVALUEMOCK'}
    end
  end
end
