require 'active_support'
require 'active_support/inflector'
require "bypass_stored_value/version"
require "bypass_stored_value/clients"
require 'savon'


module BypassStoredValue
  def self.root
    File.expand_path '../..', __FILE__
  end
end
