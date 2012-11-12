require 'test_helper'

class UPSTest < Test::Unit::TestCase
  
  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier   = UPS.new(
                   :key => '***REMOVED***',
                   :login => '***REMOVED***',
                   :password => '***REMOVED***'
                 )
    @tracking_response = xml_fixture('ups/shipment_from_tiger_direct')
  end
  
  
  def test_response_parsing
    mock_response = xml_fixture('ups/test_real_home_as_residential_destination_response')
    @carrier.expects(:commit).returns(mock_response)
    response = @carrier.find_rates( @locations[:beverly_hills],
                                    @locations[:real_home_as_residential],
                                    @packages.values_at(:chocolate_stuff))
    assert_equal [ "UPS Ground",
                   "UPS Three-Day Select",
                   "UPS Second Day Air",
                   "UPS Next Day Air Saver",
                   "UPS Next Day Air Early A.M.",
                   "UPS Next Day Air"], response.rates.map(&:service_name)
    assert_equal [9.92, 21.91, 30.07, 55.09, 94.01, 61.24], response.rates.map(&:price)
    
    date_test = [nil, 3, 2, 1, 1, 1].map do |days| 
      DateTime.strptime(days.days.from_now.strftime("%Y-%m-%d"), "%Y-%m-%d") if days
    end
    
    assert_equal date_test, response.rates.map(&:delivery_date)
  end
  
  def test_create_shipment
    response = @carrier.create_shipment( @locations[:sender_address],
                                    @locations[:cakestyle_address],
                                    @packages.values_at(:box),
                                    {:service => '03',:test => true, :key => "***REMOVED***",:login => '***REMOVED***', :password => "***REMOVED***", :origin_account => "***REMOVED***"})
    puts  "response: " + response.to_json     
    assert_equal response.class, String                   
  end
  
  def test_void_shipment
    response = @carrier.void_shipment( "","1ZISDE016691676846",{:test => true, :key => "***REMOVED***",:login => '***REMOVED***', :password => "***REMOVED***", :origin_account => "***REMOVED***"})
    assert_equal "Shipment successfully voided!", response
  end
  
end
