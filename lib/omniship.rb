require "nokogiri"
require "omniship/version"
require "omniship/carriers"
require "omniship/carriers/base"
require "omniship/carriers/fedex/rate"
require "omniship/carriers/fedex/track"
require "omniship/carriers/fedex/fedex"
# require "omniship/carriers/ups/ups"
# require "omniship/carriers/usps/usps"

module Omniship
  class Validate
    def self.required_params(params, required)
      missing_params = []
      required.each { |key| missing_params << key unless params.include?(key) }
      raise(ArgumentError.new("missing required parameters #{missing_params}")) unless missing_params.empty?
    end
  end
  class Error < StandardError ; end
end
