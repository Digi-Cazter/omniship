require_relative '../test_helper'

class ResponseTest < Minitest::Test
  def test_initialize
    assert_nothing_raised do
      RateResponse.new(true, "success!", {:rate => 'Free!'}, :rates => [stub(:service_name => 'Free!', :total_price => 0)], :xml => "<rate>Free!</rate>")
    end
    
  end
end