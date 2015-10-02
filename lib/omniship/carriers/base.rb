module Omniship
  module Carriers
    class Base
      def initialize(options={})
        Omniship::Validate.required_params(options, required_params)
        @test = options[:test] || false
        @options = options
      end
    end
  end
end
