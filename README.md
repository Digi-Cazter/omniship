[![Gem Version](https://badge.fury.io/rb/omniship.png)](http://badge.fury.io/rb/omniship) [![Code Climate](https://codeclimate.com/github/Digi-Cazter/omniship.png)](https://codeclimate.com/github/Digi-Cazter/omniship) [![Build Status](https://travis-ci.org/Digi-Cazter/omniship.svg)](https://travis-ci.org/Digi-Cazter/omniship)

[Imgur](http://i.imgur.com/6DWrBNq.png)

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
**0.4.5**
* Bug fixes for UPS
* Updated syntax for gemspec
* Updated dependencies

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
