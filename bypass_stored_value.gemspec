# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bypass_stored_value/version'

Gem::Specification.new do |spec|
  spec.name          = "bypass_stored_value"
  spec.version       = BypassStoredValue::VERSION
  spec.authors       = ["Derek Victory"]
  spec.email         = ["derek@bypassmobile.com"]
  spec.description   = %q{Gem to interface with Ceridian SVS and other stored value solutions}
  spec.summary       = %q{Connect to Stored Value Services}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'webmock'

  #Dependencies
  spec.add_dependency 'savon', '>= 2.2.0'
  spec.add_dependency('activesupport', '>= 4.0', '< 5.0.0')
end
