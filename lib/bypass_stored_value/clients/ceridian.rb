module BypassStoredValue
  module Clients
    class CeridianClient
      def initialize(user, password, args= {})
        @test_mode = args.fetch(:test_mode, true)
        @user = user
        @password = password
        namespaces = {"xmlns:ser" => "http://service.svsxml.svs.com"}
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

        response = @savon_client.call(:balance_inquiry)
      end

      private

        def wsdl
          @test_mode ? File.join(BypassStoredValue.root, 'wsdls', 'ceridian_test.wsdl.xml') : File.join(BypassStoredValue.root, 'wsdls', 'ceridian_production.wsdl.xml')
        end

        def make_request(action, message)
          response = @savon_client.call(action,message)
        end

    end
  end
end

