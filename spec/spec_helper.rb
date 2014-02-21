require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'bundler'
Bundler.setup(:default, :development)

require 'webmock/rspec'
require 'awesome_print'
require 'bypass_stored_value'
require 'nori'
require 'pry'

require_relative 'helpers/savon_logging'

savon_logger = Logger.new('log/test.log')
Savon::RequestLogger.test_logger = savon_logger
HTTPI.logger = savon_logger
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.after(:suite) do
    WebMock.disable!
  end
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file).read
end


def nori
  return @nori if @nori

  nori_options = {
    :strip_namespaces     => true,
    :convert_tags_to      => lambda { |tag| tag.snakecase.to_sym},
    :advanced_typecasting => true,
    :parser               => :nokogiri
  }

  non_nil_nori_options = nori_options.reject { |_, value| value.nil? }
  @nori = Nori.new(non_nil_nori_options)
end
