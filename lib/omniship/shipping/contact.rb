module Omniship
  module Shipping
    class Contact

      attr_reader :name,
		  :attention,
			:account,
		  :phone,
		  :fax,
		  :email

      def initialize(options={})
        @name = options[:name]
				@attention = options[:attention]
				@phone = options[:phone]
				@fax = options[:fax]
				@email = options[:email]
      end
    end
  end
end
