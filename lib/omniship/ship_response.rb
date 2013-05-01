module Omniship #:nodoc:
  class ShipResponse < Response
    attr_reader :tracking_number
    attr_reader :label_encoded

    def initialize(success, message, params = {}, options = {})
      @tracking_number = params[:tracking_number]
      @label_encoded   = params[:label_encoded]
      super
    end
  end
end