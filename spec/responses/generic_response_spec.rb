require 'spec_helper'

describe BypassStoredValue::GenericResponse do
  it 'should be successful' do
    response = BypassStoredValue::GenericResponse.new
    response.successful?.should be(true)
  end
end