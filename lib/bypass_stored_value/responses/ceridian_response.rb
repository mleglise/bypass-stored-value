module BypassStoredValue
  class CeridianResponse < BypassStoredValue::Response
    attr_accessor :response, :result, :action, :message, :return_code

    def initialize(response, action, return_successful = false)
      @response = response
      @action = action

      if return_successful
        @return_code = '01'
        @balance_amount = '0'
        @message = 'Approved'
      else
        parse_action(action)
      end

    end

    def successful?
      @return_code == '01'
    end

    def balance
      @balance_amount
    end

    def hash
      @response.hash
    rescue
      {}
    end

    private

    def parse_action(action)
      @return_code = @response.hash[:envelope][:body][:"#{action.to_s}_response"][:"#{action}_return"][:return_code][:return_code]
      @message = @response.hash[:envelope][:body][:"#{action.to_s}_response"][:"#{action}_return"][:return_code][:return_description]
      @transaction_id = @response.hash[:envelope][:body][:"#{action.to_s}_response"][:"#{action}_return"][:stan] rescue nil
      @balance_amount = @response.hash[:envelope][:body][:"#{action.to_s}_response"][:"#{action}_return"][:balance_amount][:amount] rescue nil
    end

  end
 end