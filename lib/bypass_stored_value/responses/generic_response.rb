module BypassStoredValue
  class GenericResponse < BypassStoredValue::Response

    def initialize
    end
    
    def successful?
      true
    end
  end
end