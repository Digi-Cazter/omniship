# FedEx module by Jimmy Baker
# http://github.com/jimmyebaker

module Omniship
  # :key is your developer API key
  # :password is your API password
  # :account is your FedEx account number
  # :login is your meter number
  class FedEx < Carrier
    self.retry_safe = true

    cattr_reader :name
    @@name = "FedEx"

    TEST_URL = 'https://gatewaybeta.fedex.com:443/xml'
    LIVE_URL = 'https://gateway.fedex.com:443/xml'

    CarrierCodes = {
      "fedex_ground"  => "FDXG",
      "fedex_express" => "FDXE"
    }

    ServiceTypes = {
      "PRIORITY_OVERNIGHT"                       => "FedEx Priority Overnight",
      "PRIORITY_OVERNIGHT_SATURDAY_DELIVERY"     => "FedEx Priority Overnight Saturday Delivery",
      "FEDEX_2_DAY"                              => "FedEx 2 Day",
      "FEDEX_2_DAY_SATURDAY_DELIVERY"            => "FedEx 2 Day Saturday Delivery",
      "STANDARD_OVERNIGHT"                       => "FedEx Standard Overnight",
      "FIRST_OVERNIGHT"                          => "FedEx First Overnight",
      "FIRST_OVERNIGHT_SATURDAY_DELIVERY"        => "FedEx First Overnight Saturday Delivery",
      "FEDEX_EXPRESS_SAVER"                      => "FedEx Express Saver",
      "FEDEX_1_DAY_FREIGHT"                      => "FedEx 1 Day Freight",
      "FEDEX_1_DAY_FREIGHT_SATURDAY_DELIVERY"    => "FedEx 1 Day Freight Saturday Delivery",
      "FEDEX_2_DAY_FREIGHT"                      => "FedEx 2 Day Freight",
      "FEDEX_2_DAY_FREIGHT_SATURDAY_DELIVERY"    => "FedEx 2 Day Freight Saturday Delivery",
      "FEDEX_3_DAY_FREIGHT"                      => "FedEx 3 Day Freight",
      "FEDEX_3_DAY_FREIGHT_SATURDAY_DELIVERY"    => "FedEx 3 Day Freight Saturday Delivery",
      "INTERNATIONAL_PRIORITY"                   => "FedEx International Priority",
      "INTERNATIONAL_PRIORITY_SATURDAY_DELIVERY" => "FedEx International Priority Saturday Delivery",
      "INTERNATIONAL_ECONOMY"                    => "FedEx International Economy",
      "INTERNATIONAL_FIRST"                      => "FedEx International First",
      "INTERNATIONAL_PRIORITY_FREIGHT"           => "FedEx International Priority Freight",
      "INTERNATIONAL_ECONOMY_FREIGHT"            => "FedEx International Economy Freight",
      "GROUND_HOME_DELIVERY"                     => "FedEx Ground Home Delivery",
      "FEDEX_GROUND"                             => "FedEx Ground",
      "INTERNATIONAL_GROUND"                     => "FedEx International Ground"
    }

    PackageTypes = {
      "fedex_envelope"  => "FEDEX_ENVELOPE",
      "fedex_pak"       => "FEDEX_PAK",
      "fedex_box"       => "FEDEX_BOX",
      "fedex_tube"      => "FEDEX_TUBE",
      "fedex_10_kg_box" => "FEDEX_10KG_BOX",
      "fedex_25_kg_box" => "FEDEX_25KG_BOX",
      "your_packaging"  => "YOUR_PACKAGING"
    }

    DropoffTypes = {
      'regular_pickup'          => 'REGULAR_PICKUP',
      'request_courier'         => 'REQUEST_COURIER',
      'dropbox'                 => 'DROP_BOX',
      'business_service_center' => 'BUSINESS_SERVICE_CENTER',
      'station'                 => 'STATION'
    }

    PaymentTypes = {
      'sender'      => 'SENDER',
      'recipient'   => 'RECIPIENT',
      'third_party' => 'THIRDPARTY',
      'collect'     => 'COLLECT'
    }

    PackageIdentifierTypes = {
      'tracking_number'           => 'TRACKING_NUMBER_OR_DOORTAG',
      'door_tag'                  => 'TRACKING_NUMBER_OR_DOORTAG',
      'rma'                       => 'RMA',
      'ground_shipment_id'        => 'GROUND_SHIPMENT_ID',
      'ground_invoice_number'     => 'GROUND_INVOICE_NUMBER',
      'ground_customer_reference' => 'GROUND_CUSTOMER_REFERENCE',
      'ground_po'                 => 'GROUND_PO',
      'express_reference'         => 'EXPRESS_REFERENCE',
      'express_mps_master'        => 'EXPRESS_MPS_MASTER'
    }

    def self.service_name_for_code(service_code)
      ServiceTypes[service_code] || begin
        name = service_code.downcase.split('_').collect{|word| word.capitalize }.join(' ')
        "FedEx #{name.sub(/Fedex /, '')}"
      end
    end

    def requirements
      [:key, :account, :meter, :password]
    end

    def find_rates(origin, destination, packages, options = {})
      options      = @options.merge(options)
      packages     = Array(packages)
      rate_request = build_rate_request(origin, destination, packages, options)
      response     = commit(save_request(rate_request), (options[:test] || false)).gsub(/<(\/)?.*?\:(.*?)>/, '<\1\2>')
      parse_rate_response(origin, destination, packages, response, options)
    end

    # def create_shipment(origin, destination, packages, options = {})
    #   options      = @options.merge(options)
    #   packages     = Array(packages)
    #   ship_request = build_ship_request(origin, destination, packages, options)
    #   response     = commit(save_request(ship_request.gsub("\n", "")), options[:test])
    #   #parse_ship_response(origin, destination, packages, response, options)
    # end

    def create_shipment(origin, destination, packages, options={})
      options        = @options.merge(options)
      options[:test] = options[:test].nil? ? true : options[:test]
      packages       = Array(packages)
      access_request = build_access_request
      ship_request   = build_ship_request(origin, destination, packages, options)
      access_request.gsub("\n", "") + ship_request.gsub("\n", "")
      # response       = commit(save_request(access_request.gsub("\n", "") + ship_request.gsub("\n", "")), options[:test])
      # response     = commit(:shipconfirm, save_request(access_request.gsub("\n", "") + ship_confirm_request.gsub("\n", "")), options[:test])
      # parse_ship_confirm_response(origin, destination, packages, response, options)
    end

    def find_tracking_info(tracking_number, options={})
      options          = @options.update(options)
      tracking_request = build_tracking_request(tracking_number, options)
      response         = commit(save_request(tracking_request), (options[:test] || false)).gsub(/<(\/)?.*?\:(.*?)>/, '<\1\2>')
      parse_tracking_response(response, options)
    end

    protected
    def build_rate_request(origin, destination, packages, options={})
      imperial = ['US','LR','MM'].include?(origin.country_code(:alpha2))

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.RateRequest {
          xml.ReturnTransitAndCommit true
          xml.VariableOptions 'SATURDAY_DELIVERY'
          xml.RequestedShipment {
            xml.ShipTimestamp Time.now
            xml.DropoffType options[:dropoff_type] || 'REGULAR_PICKUP'
            xml.PackagingType options[:packaging_type] || 'YOUR_PACKAGING'
            build_location_node('Shipper', (options[:shipper] || origin))
            build_location_node('Recipient', destination)
            if options[:shipper] && options[:shipper] != origin
              build_location_node('Origin', origin)
            end
            xml.RateRequestTypes 'ACCOUNT'
            xml.PackageCount packages.size
            packages.each do |pkg|
              xml.RequestedPackages {
                xml.Weight {
                  xml.Units (imperial ? 'LB' : 'KG')
                  xml.Value ([((imperial ? pkg.lbs : pgk.kgs).to_f*1000).round/1000.0, 0.1].max)
                }
                xml.Dimensions {
                  [:length, :width, :height].each do |axis|
                    name  = axis.to_s.capitalize
                    value = ((imperial ? pkg.inches(axis) : pkg.cm(axis)).to_f*1000).round/1000.0
                    xml.name value
                  end
                  xml.Units (imperial ? 'IN' : 'CM')
                }
              }
            end
          }
        }
      end
      builder.to_xml
    end

    def build_ship_request(origin, destination, packages, options={})
      imperial = ['US','LR','MM'].include?(origin.country_code(:alpha2))

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.RequestedShipment {
          xml.DropoffType options[:dropoff_type] || 'REGULAR_PICKUP'
          xml.PackagingType options[:service_type] || 'FEDEX_GROUND'
          xml.PackagingType options[:package_type] || 'YOUR_PACKAGING'
          xml.ShipTimestamp Time.now
          xml.VariableOptions '' #'SATURDAY_DELIVERY'
          xml.ReturnTransitAndCommit true
          xml.Company options[:company]
          xml.Contact options[:contact]
          build_location_node("Shipper", (options[:shipper] || origin))
          build_location_node("Recipient", destination)
          if options[:shipper] && options[:shipper] != origin
            build_location_node("Origin", origin)
          end
          xml.PackageCount packages.size
          packages.each do |pkg|
            xml.RequestedPackages {
              xml.Weight {
                xml.Units (imperial ? 'LB' : 'KG')
                xml.Value ([((imperial ? pkg.lbs : pgk.kgs).to_f*1000).round/1000.0, 0.1].max)
              }
              xml.Dimensions {
                [:length, :width, :height].each do |axis|
                  name  = axis.to_s.capitalize
                  value = ((imperial ? pkg.inches(axis) : pkg.cm(axis)).to_f*1000).round/1000.0
                  xml.send name, value
                end
                xml.Units (imperial ? 'IN' : 'CM')
              }
            }
          end
        }
      end
      builder.doc.root.to_xml
    end

    def build_tracking_request(tracking_number, options={})
      xml_request = XmlNode.new('TrackRequest', 'xmlns' => 'http://fedex.com/ws/track/v3') do |root_node|
        root_node << build_request_header

        # Version
        root_node << XmlNode.new('Version') do |version_node|
          version_node << XmlNode.new('ServiceId', 'trck')
          version_node << XmlNode.new('Major', '3')
          version_node << XmlNode.new('Intermediate', '0')
          version_node << XmlNode.new('Minor', '0')
        end

        root_node << XmlNode.new('PackageIdentifier') do |package_node|
          package_node << XmlNode.new('Value', tracking_number)
          package_node << XmlNode.new('Type', PackageIdentifierTypes[options['package_identifier_type'] || 'tracking_number'])
        end

        root_node << XmlNode.new('ShipDateRangeBegin', options['ship_date_range_begin']) if options['ship_date_range_begin']
        root_node << XmlNode.new('ShipDateRangeEnd', options['ship_date_range_end']) if options['ship_date_range_end']
        root_node << XmlNode.new('IncludeDetailedScans', 1)
      end
      xml_request.to_s
    end

    def build_access_request
      web_authentication_detail = Nokogiri::XML::Builder.new do |xml|
        xml.WebAuthenticationDetail {
          xml.UserCredential {
            xml.Key @options[:key]
            xml.Password @options[:password]
          }
        }
      end

      client_detail = Nokogiri::XML::Builder.new do |xml|
        xml.ClientDetail {
          xml.AccountNumber @options[:account]
          xml.MeterNumber @options[:meter]
        }
      end

      transaction_detail = Nokogiri::XML::Builder.new do |xml|
        xml.TransactionDetail {
          xml.CustomerTransactionId 'Omniship' # TODO: Need to do something better with this...
        }
      end

      [web_authentication_detail.doc.root.to_xml, client_detail.doc.root.to_xml, transaction_detail.doc.root.to_xml].join
    end

    def build_location_node(name, location)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.name {
          xml.Address {
            xml.StreetLines [location.address1, (location.address2 if !location.address2.nil?)]
            xml.City location.city
            xml.StateOrProvinceCode location.state
            xml.PostalCode location.postal_code
            xml.CountryCode location.country_code(:alpha2)
            xml.PhoneNumber location.phone
            xml.Residential true unless location.commercial?
          }
        }
      end
      builder.doc.root.to_xml
    end

    def parse_rate_response(origin, destination, packages, response, options)
      rate_estimates = []
      success, message = nil

      xml = REXML::Document.new(response)
      root_node = xml.elements['RateReply']

      success = response_success?(xml)
      message = response_message(xml)

      root_node.elements.each('RateReplyDetails') do |rated_shipment|
        service_code = rated_shipment.get_text('ServiceType').to_s
        is_saturday_delivery = rated_shipment.get_text('AppliedOptions').to_s == 'SATURDAY_DELIVERY'
        service_type = is_saturday_delivery ? "#{service_code}_SATURDAY_DELIVERY" : service_code

        currency = handle_uk_currency(rated_shipment.get_text('RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Currency').to_s)
        rate_estimates << RateEstimate.new(origin, destination, @@name,
                            self.class.service_name_for_code(service_type),
                            :service_code => service_code,
                            :total_price => rated_shipment.get_text('RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Amount').to_s.to_f,
                            :currency => currency,
                            :packages => packages,
                            :delivery_range => [rated_shipment.get_text('DeliveryTimestamp').to_s] * 2)
      end

      if rate_estimates.empty?
        success = false
        message = "No shipping rates could be found for the destination address" if message.blank?
      end

      RateResponse.new(success, message, Hash.from_xml(response), :rates => rate_estimates, :xml => response, :request => last_request, :log_xml => options[:log_xml])
    end

    def parse_tracking_response(response, options)
      xml = REXML::Document.new(response)
      root_node = xml.elements['TrackReply']

      success = response_success?(xml)
      message = response_message(xml)

      if success
        tracking_number, origin, destination = nil
        shipment_events = []

        tracking_details = root_node.elements['TrackDetails']
        tracking_number = tracking_details.get_text('TrackingNumber').to_s

        destination_node = tracking_details.elements['DestinationAddress']
        destination = Address.new(
              :country =>     destination_node.get_text('CountryCode').to_s,
              :province =>    destination_node.get_text('StateOrProvinceCode').to_s,
              :city =>        destination_node.get_text('City').to_s
            )

        tracking_details.elements.each('Events') do |event|
          address  = event.elements['Address']

          city     = address.get_text('City').to_s
          state    = address.get_text('StateOrProvinceCode').to_s
          zip_code = address.get_text('PostalCode').to_s
          country  = address.get_text('CountryCode').to_s
          next if country.blank?

          location = Address.new(:city => city, :state => state, :postal_code => zip_code, :country => country)
          description = event.get_text('EventDescription').to_s

          # for now, just assume UTC, even though it probably isn't
          time = Time.parse("#{event.get_text('Timestamp').to_s}")
          zoneless_time = Time.utc(time.year, time.month, time.mday, time.hour, time.min, time.sec)

          shipment_events << ShipmentEvent.new(description, zoneless_time, location)
        end
        shipment_events = shipment_events.sort_by(&:time)
      end

      TrackingResponse.new(success, message, Hash.from_xml(response),
        :xml => response,
        :request => last_request,
        :shipment_events => shipment_events,
        :destination => destination,
        :tracking_number => tracking_number
      )
    end

    def response_status_node(document)
      document.elements['/*/Notifications/']
    end

    def response_success?(document)
      %w{SUCCESS WARNING NOTE}.include? response_status_node(document).get_text('Severity').to_s
    end

    def response_message(document)
      response_node = response_status_node(document)
      "#{response_status_node(document).get_text('Severity').to_s} - #{response_node.get_text('Code').to_s}: #{response_node.get_text('Message').to_s}"
    end

    def commit(request, test = false)
      ssl_post(test ? TEST_URL : LIVE_URL, request.gsub("\n",''))
    end

    def handle_uk_currency(currency)
      currency =~ /UKL/i ? 'GBP' : currency
    end
  end
end
