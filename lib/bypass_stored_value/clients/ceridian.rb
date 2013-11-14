module BypassStoredValue
  module Clients
    class CeridianClient
      def initialize(user, password, args= {})
        @test_mode = args.fetch(:test_mode, true)
        @user = user
        @password = password
        namespaces = {"xmlns:ser" => "https://#{server_name}/svsxml/services/SVSXMLWay"}
        @savon_client = Savon.client({
          wsdl: wsdl,
          namespaces: namespaces,
          env_namespace: :soapenv,
          namespace_identifier: 'ser',
          wsse_auth: [@user, @password],
          pretty_print_xml: true
        })
      end

      def get_balance
        response = @savon_client.call(:balance_inquiry_request)
      end

      private

      def wsdl
        @test_mode ? File.join(BypassStoredValue.root, 'wsdls', 'ceridian_test.wsdl.xml') : File.join(BypassStoredValue.root, 'wsdls', 'ceridian_production.wsdl.xml')
      end

      def server_name
        @test_mode ? "webservices-cert.storedvalue.com" : "webservices.storedvalue.com"
      end

    end
  end
end

