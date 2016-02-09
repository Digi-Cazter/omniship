#--
# Copyright (c) 2009 Jaded Pixel
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

### TODO Working on creating code for using an initializer for configuration ###

require 'omniship/base'

def Omniship.setup
  @root   = Rails.root
  if @root
    @boot   = File.join(@root, "config", "boot.rb").freeze
    @config = File.join(@root, "config", "omniship.yml").freeze
    @keys   = %w{ username password key account meter }.map { |v| v.freeze }.freeze
    require boot unless defined? Rails.env
    if File.exists? @config
      @config = YAML.load_file(@config)
      raise "Invalid omniship configuration file: #{@config}" unless @config.is_a?(Hash)
      if (@config.keys & @keys).sort == @keys.sort and !@config.has_key?(Rails.env)
        @config[Rails.env] = {
          "ups"   => @config["ups"],
          "fedex" => @config["fedex"],
          "usps"  => @config["usps"]
        }
      end
      @config[Rails.env].freeze
    end
  end
end

$:.unshift File.dirname(__FILE__)

begin
  require 'active_support/all'
rescue LoadError => e
  require 'rubygems'
  gem "activesupport", ">= 2.3.5"
  require "active_support/all"
end

autoload :XmlNode, 'vendor/xml_node/lib/xml_node'
autoload :Quantified, 'vendor/quantified/lib/quantified'

require 'net/https'
require 'active_utils'
require 'nokogiri'

require 'omniship/base'
require 'omniship/contact'
require 'omniship/response'
require 'omniship/rate_response'
require 'omniship/tracking_response'
require 'omniship/package'
require 'omniship/address'
require 'omniship/rate_estimate'
require 'omniship/carrier'
require 'omniship/carriers'
require 'omniship/shipment_event'
require 'omniship/ship_response'
