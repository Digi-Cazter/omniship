require 'omniship/shipping/carriers/ups'
require 'omniship/shipping/carriers/usps'
require 'omniship/shipping/carriers/fedex'

module Omniship
  module Shipping
    module Carriers
      class <<self
        def all
          [UPS, USPS, FedEx]
        end
      end
    end
  end
end