require_relative '../../test_helper'

class UPSTest < Minitest::Test

  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier   = UPS.new(
                   :key => "#TODO",
                   :login => "#TODO",
                   :password => "#TODO"
                 )
    @tracking_response = xml_fixture('ups/shipment_from_tiger_direct')
  end
  
  def test_tracking_info
    shipment_info = @carrier.find_tracking_info("1Z0X505E9090010777",{:test => true,:key => '#TODO',:login => '#TODO', :password => "#TODO", :origin_account => "#TODO"})
    puts shipment_info.to_json
    assert_equal shipment_info.class, Hash
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
                                    {:service => '03',:test => true, :key => "#TODO",:login => '#TODO', :password => "#TODO", :origin_account => "#TODO"})
    puts  "response: " + response.to_json     
    assert_equal response.class, String                   
  end
  
  def test_void_shipment
    response = @carrier.void_shipment( "","1ZISDE016691676846",{:test => true, :key => "#TODO",:login => '#TODO', :password => "#TODO", :origin_account => "#TODO"})
    assert_equal "Shipment successfully voided!", response
  end
  
  def test_validate_address
     response = @carrier.validate_address( '455 N REXFORD DR','BEVERLY HILLS','CA','90210','US',{:test => true, :key => "#TODO",:login => '#TODO', :password => "#TODO", :origin_account => "#TODO"})
     if response.is_a? Array
        address_hash = {:address => '455 N REXFORD DR',:city=>"BEVERLY HILLS",:state=>"CA",:zip_code=>"90210",:country_code=>"US"}
        assert_equal address_hash , response.first
     end
  end
  
end
