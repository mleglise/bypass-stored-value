module BypassStoredValue
  class StadisResponse < BypassStoredValue::Response
    attr_accessor :response, :result, :action

    ACTIONS = ["Stadis Account Charge", "Stadis Settle", "Stadis Post Transaction", "Stadis Reload", "Stadis Refund", "Stadis Balance Check"]

    def initialize(response, action)
      @response = response.body unless response.nil? || response.body.nil?
      @action = action
      parse
    end

    def parse
      raise BypassStoredValue::Exception::ActionNotFound unless ACTIONS.include?(action.titleize)
      return stadis_settle if response.nil? and action == "stadis_settle"
      send("build_#{action}_response")
      result
    end

    def successful?
      result[:status_code] >= 0
    end

    def transaction_id
      result[:authentication_token]
    end

    def refunded_amount
      result[:charged_amount] if action == "stadis_refund"
    end

    private

    def stadis_settle
      @result = {status_code: 0}
    end

    def build_stadis_post_transaction_response
      @result = {status_code: response[:post_transaction_response][:post_transaction_result][:return_message][:return_code].to_i}
    end

    def build_stadis_account_charge_response
      build_standard_stadis_result_hash(response[:stadis_account_charge_response][:stadis_account_charge_result])
    end

    def build_stadis_balance_check_response
      build_standard_stadis_result_hash(response[:stadis_balance_check_response][:stadis_balance_check_result])
    end

    def build_stadis_refund_response
      build_standard_stadis_result_hash(response[:reverse_stadis_account_charge_response][:reverse_stadis_account_charge_result])
    end

    def build_stadis_reload_response
      build_standard_stadis_result_hash(response[:reload_gift_card_response][:reload_gift_card_result])
    end

    def build_standard_stadis_result_hash(response_hash)
      @result = {
        status_code: response_hash[:return_message][:return_code].to_i,
        authentication_token: response_hash[:stadis_reply][:stadis_authorization_id],
        charged_amount: response_hash[:stadis_reply][:charged_amount].to_f,
        remaining_balance: response_hash[:stadis_reply][:remaining_amount].to_f}
    end
  end
end
