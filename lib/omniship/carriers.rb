module Omniship
  module Carriers
    class <<self
      def all
        [UPS, USPS, FedEx]
      end
    end
  end
end
