module BypassStoredValue
  class Response
    attr_accessor :response, :result, :action

    ACTIONS = ["Stadis Account Charge", "Stadis Post Transaction", "Stadis Reload", "Stadis Refund"]

    def initialize(response, action)
      @response = response.body unless response.nil? || response.body.nil?
      @result = {}
      @action = action
      parse
    end

    def parse
      #Stadis responses only currently
      return empty_response if response.nil?
      raise BypassStoredValue::Exception::ActionNotFound unless ACTIONS.include?(action.titleize)
      send("build_#{action}_response")
      result
    end
    
    def successful?
      result[:status_code] >= 0
    end

    private

    def empty_response
      result[:status_code] = -99
    end

    def build_stadis_post_transaction_response
      result[:status_code] = response[:post_transaction_response][:post_transaction_result][:return_message][:return_code]
    end

    def build_stadis_account_charge_response
      result[:status_code] = response[:stadis_account_charge_response][:stadis_account_charge_result][:return_message][:return_code].to_i
      result[:authentication_token] = response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:stadis_authorization_id]
      result[:charged_amount] = response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:charged_amount].to_f
      result[:remaining_balance] = response[:stadis_account_charge_response][:stadis_account_charge_result][:stadis_reply][:remaining_amount].to_f
    end

    def build_stadis_refund_response
      result[:status_code] = response[:reverse_stadis_account_charge_response][:reverse_stadis_account_charge_result][:return_message][:return_code].to_i
      result[:authentication_token] = response[:reverse_stadis_account_charge_response][:reverse_stadis_account_charge_result][:stadis_reply][:stadis_authorization_id]
      result[:charged_amount] = response[:reverse_stadis_account_charge_response][:reverse_stadis_account_charge_result][:stadis_reply][:charged_amount].to_f
      result[:remaining_balance] = response[:reverse_stadis_account_charge_response][:reverse_stadis_account_charge_result][:stadis_reply][:remaining_amount].to_f
    end

    def build_stadis_reload_response
      result[:status_code] = response[:reload_gift_card_response][:reload_gift_card_result][:return_message][:return_code].to_i
      result[:authentication_token] = response[:reload_gift_card_response][:reload_gift_card_result][:stadis_reply][:stadis_authorization_id]
      result[:charged_amount] = response[:reload_gift_card_response][:reload_gift_card_result][:stadis_reply][:charged_amount].to_f
      result[:remaining_balance] = response[:reload_gift_card_response][:reload_gift_card_result][:stadis_reply][:remaining_amount].to_f
    end
  end
end
