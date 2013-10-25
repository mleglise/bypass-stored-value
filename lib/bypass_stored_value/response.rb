module BypassStoredValue
  class Response
    attr_accessor :response, :result

    def initialize(response)
      @response = response.body unless response.nil? || response.body.nil?
      @result = {}
      parse
    end

    def parse
      #Stadis responses only currently
      return empty_response if response.nil?
      result[:status_code] = response[:status_code] 
      result[:authentication_token] = response[:stadis_authorization_id]
      result[:charged_amount] = response[:charged_amount]
    end

    def empty_response
      result[:status_code] = -99
    end

    def successful?
      result[:status_code] >= 0
    end
  end
end
