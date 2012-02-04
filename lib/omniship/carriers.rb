require 'omniship/carriers/ups'
require 'omniship/carriers/usps'
require 'omniship/carriers/fedex'

module Omniship
  module Carriers
    class <<self
      def all
        [UPS, USPS, FedEx]
      end
    end
  end
end