[![Gem Version](https://badge.fury.io/rb/omniship.png)](http://badge.fury.io/rb/omniship) [![Code Climate](https://codeclimate.com/github/Digi-Cazter/omniship.png)](https://codeclimate.com/github/Digi-Cazter/omniship) [![Build Status](https://travis-ci.org/Digi-Cazter/omniship.svg)](https://travis-ci.org/Digi-Cazter/omniship)

![Omniship Logo]
(http://i.imgur.com/6DWrBNq.png)

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

## Tests

Currently this is on my TODO list. Check back for updates

## Change Log

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/digi-cazter/omniship. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](www.contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
