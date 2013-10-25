require 'spec_helper'

describe BypassStoredValue::MockResponse do
  it "should call #generate_successful_response" do
    BypassStoredValue::MockResponse.any_instance.should_receive(:generate_successful_response)
    BypassStoredValue::MockResponse.any_instance.should_not_receive(:generate_failed_response)
    BypassStoredValue::MockResponse.new({
      "ReferenceNumber" => "byp_#{rand(10**6)}",
      "RegisterID" => 1,
      "VendorCashier" => 1,
      "TransactionType" => 1,
      "TenderTypeID" => 1,
      "TenderID" => '1234',
      "Amount" => 2.00})
  end

  it "should call #generate_failed_response if the given amount is less than 0" do
    BypassStoredValue::MockResponse.any_instance.should_receive(:generate_failed_response)
    BypassStoredValue::MockResponse.new({
      "ReferenceNumber" => "byp_#{rand(10**6)}",
      "RegisterID" => 1,
      "VendorCashier" => 1,
      "TransactionType" => 1,
      "TenderTypeID" => 1,
      "TenderID" => '1234',
      "Amount" => -2.00})
  end
end
