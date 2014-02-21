module Savon
  class RequestLogger

    class << self
      attr_accessor :test_logger
    end

    def logger
      self.class.test_logger
    end
  end
end
