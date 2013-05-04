module Omniship #:nodoc:
  class Notification
    attr_reader :options
    attr_reader :email
    attr_reader :format
    attr_reader :language
    attr_reader :locale_code

    alias_method :email_address, :email

    def initialize(options = {})
      @email       = options[:email]
      @format      = options[:format]
      @language    = options[:language]
      @locale_code = options[:locale_code]
    end
  end
end