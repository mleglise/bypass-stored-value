require 'spec_helper'

describe BypassStoredValue::Clients::StadisClient do
  ACCOUNT_NUMBER = "14245134044543"

  context "An instance of the Stadis::Client class" do
    it "adds credentials in soap header" do
      Savon.should_receive(:client).with(endpoint: "http://localhost:3000/StadisWeb/StadisTransactions.asmx",
          namespace: "http://www.STADIS.com/",
          read_timeout: 5000,
          open_timeout: 360,
          element_form_default: :unqualified,
          namespace_identifier: nil,
          ssl_verify_mode: :none,
          env_namespace: :soap,
          soap_header: {
            "SecurityCredentials" => {
                "UserID" => "testuser",
                "Password" => "password"
            },
            :attributes! => {"SecurityCredentials" => {"xmlns" => "http://www.STADIS.com/"}}
          })
      client = BypassStoredValue::Clients::StadisClient.new("http", "localhost", "3000", "1", "1", "byp_#{10**6}", "BLFB", "1", "testuser", "password")

    end
  end
end
