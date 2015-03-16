[![Gem Version](https://badge.fury.io/rb/omniship.png)](http://badge.fury.io/rb/omniship) [![Code Climate](https://codeclimate.com/github/Digi-Cazter/omniship.png)](https://codeclimate.com/github/Digi-Cazter/omniship)

# Omniship

This gem is under active development, I'm only in the Alpha stage right now, so keep checking back for updates.

This library has been created to make web requests to common shipping carriers using XML.  I created this to be easy to use with a nice Ruby API.  This code was originally forked from the *Shopify/active_shipping* code, I began to strip it down cause I wan't a cleaner API along with the ability to actually create shipment labels with it.  After changing enough code, I created this gem as its own project since it's different enough.

## Supported Shipping Carriers

* [UPS](http://www.ups.com)
  - Create Shipment
  - Void Shipment
  - Get Rates
  - Validate Address
  - Validate Address with Street
* [FedEx](http://www.fedex.com) (These listed features work, but still need more options added)
  - Create Shipment
  - Void Shipment
  - Get Rates
  - Shipment Tracking
* [USPS](http://www.usps.com) COMING SOON!

## Simple example snippets
### UPS Code Example ###
To run in test mode during development, pass :test => true as an option
into create_shipment and accept_shipment.

      def create_shipment
      # If you have created the omniship.yml config file
      @config  = OMNISHIP_CONFIG[Rails.env]['ups']
      shipment = create_ups_shipment
    end

    def create_ups_shipment
      # If using the yml config
      ups = Omniship::UPS.new
      # Else just pass in the credentials
      ups = Omniship::UPS.new(:login => @user, :password => @password, :key => @key)
      send_options = {}
      send_options[:origin_account] = @config["account"] # Or just put the shipper account here
      send_options[:service]        = "03"
      response = ups.create_shipment(origin, destination, package, options = send_options)
      return ups.accept_shipment(response)
    end

    def origin
      address = {}
      address[:name]     = "My House"
      address[:address1] = "555 Diagonal"
      address[:city]     = "Saint George"
      address[:state]    = "UT"
      address[:zip]      = "84770"
      address[:country]  = "USA"
      return Omniship::Address.new(address)
    end

    def destination
      address = {}
      address[:company_name] = "Wal-Mart"
      address[:address1]     = "555 Diagonal"
      address[:city]         = "Saint George"
      address[:state]        = "UT"
      address[:zip]          = "84770"
      address[:country]      = "USA"
      return Omniship::Address.new(address)
    end

    def packages
      # UPS can handle a single package or multiple packages
      pkg_list = []
      weight = 1
      length = 1
      width  = 1
      height = 1
      package_type = "02"
      pkg_list << Omniship::Package.new(weight.to_i,[length.to_i,width.to_i,height.to_i],:units => :imperial, :package_type => package_type)
      return pkg_list
    end

## Tests

Currently this is on my TODO list. Check back for updates

## Change Log
**0.4.1**

* Bug fixes for dependencies

## Contributing

Before anyone starts contributing, I want to get a good stable version going and tests to follow, after I get that going then for the features you add, you should have both unit tests and remote tests. It's probably best to start with the remote tests, and then log those requests and responses and use them as the mocks for the unit tests.

To log requests and responses, just set the `logger` on your carrier class to some kind of `Logger` object:

    Omniship::USPS.logger = Logger.new($stdout)

(This logging functionality is provided by the [`PostsData` module](https://github.com/Shopify/active_utils/blob/master/lib/active_utils/common/posts_data.rb) in the `active_utils` dependency.)

After you've pushed your well-tested changes to your github fork, make a pull request and we'll take it from there!

## Legal Mumbo Jumbo

Unless otherwise noted in specific files, all code in the Omniship project is under the copyright and license described in the included MIT-LICENSE file.
