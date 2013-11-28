# FedEx module by Donavan White

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
      options        = @options.merge(options)
      options[:test] = options[:test].nil? ? true : options[:test]
      packages       = Array(packages)
      rate_request   = build_rate_request(origin, destination, packages, options)
      response       = commit(save_request(rate_request.gsub("\n", "")), options[:test])
      parse_rate_response(origin, destination, packages, response, options)
    end

    def create_shipment(origin, destination, packages, options={})
      options        = @options.merge(options)
      options[:test] = options[:test].nil? ? true : options[:test]
      packages       = Array(packages)
      ship_request   = build_ship_request(origin, destination, packages, options)
      response       = commit(save_request(ship_request.gsub("\n", "")), options[:test])
      parse_ship_response(response, options)
    end

    def delete_shipment(tracking_number, shipment_type, options={})
      options                 = @options.merge(options)
      delete_shipment_request = build_delete_request(tracking_number, shipment_type, options)
      response                = commit(save_request(delete_shipment_request.gsub("\n", "")), options[:test])
      parse_delete_response(response, options)
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
        xml.RateRequest('xmlns' => 'http://fedex.com/ws/rate/v12') {
          build_access_request(xml)
          xml.Version {
            xml.ServiceId "crs"
            xml.Major "12"
            xml.Intermediate "0"
            xml.Minor "0"
          }
          xml.RequestedShipment {
            xml.ShipTimestamp options[:ship_date] || DateTime.now.strftime
            xml.DropoffType options[:dropoff_type] || 'REGULAR_PICKUP'
            xml.PackagingType options[:packaging_type] || 'YOUR_PACKAGING'
            build_location_node(['Shipper'], (options[:shipper] || origin), xml)
            build_location_node(['Recipient'], destination, xml)
            if options[:shipper] && options[:shipper] != origin
              build_location_node(['Origin'], origin, xml)
            end
            xml.RateRequestTypes 'ACCOUNT'
            xml.PackageCount packages.size
            packages.each do |pkg|
              xml.RequestedPackageLineItems {
                xml.SequenceNumber 1
                xml.GroupPackageCount 1
                xml.Weight {
                  xml.Units (imperial ? 'LB' : 'KG')
                  xml.Value ((imperial ? pkg.weight : pkg.weight/2.2).to_f)
                }
                # xml.Dimensions {
                #   [:length, :width, :height].each do |axis|
                #     name  = axis.to_s.capitalize
                #     value = ((imperial ? pkg.inches(axis) : pkg.cm(axis)).to_f*1000).round/1000.0
                #     xml.name value
                #   end
                #   xml.Units (imperial ? 'IN' : 'CM')
                # }
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
        xml.ProcessShipmentRequest('xmlns' => 'http://fedex.com/ws/ship/v12') {
          build_access_request(xml)
          xml.Version {
            xml.ServiceId "ship"
            xml.Major "12"
            xml.Intermediate "0"
            xml.Minor "0"
          }
          xml.RequestedShipment {
            xml.ShipTimestamp options[:ship_date] || DateTime.now.strftime
            xml.DropoffType options[:dropoff_type] || 'REGULAR_PICKUP'
            xml.ServiceType options[:service_type] || 'GROUND_HOME_DELIVERY'
            xml.PackagingType options[:package_type] || 'YOUR_PACKAGING'
            build_location_node(["Shipper"], (options[:shipper] || origin), xml)
            build_location_node(["Recipient"], destination, xml)
            if options[:shipper] && options[:shipper] != origin
              build_location_node(["Origin"], origin, xml)
            end
            xml.ShippingChargesPayment {
              xml.PaymentType "SENDER"
              xml.Payor {
                xml.ResponsibleParty {
                  xml.AccountNumber @options[:account]
                  xml.Contact nil
                }
              }
            }
            xml.SpecialServicesRequested {
              xml.SpecialServiceTypes "SATURDAY_DELIVERY" if options[:saturday_delivery]
              if options[:return_shipment]
                xml.SpecialServiceTypes "RETURN_SHIPMENT"
                xml.ReturnShipmentDetail {
                  xml.ReturnType "PRINT_RETURN_LABEL"
                }
              end
            }
            xml.LabelSpecification {
              xml.LabelFormatType 'COMMON2D'
              xml.ImageType 'PDF'
              xml.LabelStockType 'PAPER_7X4.75'
            }
            xml.RateRequestTypes 'ACCOUNT'
            xml.PackageCount packages.size
            packages.each do |pkg|
              xml.RequestedPackageLineItems {
                xml.SequenceNumber 1
                xml.Weight {
                  xml.Units (imperial ? 'LB' : 'KG')
                  xml.Value ((imperial ? pkg.weight : pkg.weight/2.2).to_f)
                }
                # xml.Dimensions {
                #   [:length, :width, :height].each do |axis|
                #     name  = axis.to_s.capitalize
                #     value = ((imperial ? pkg.inches(axis) : pkg.cm(axis)).to_f*1000).round/1000.0
                #     xml.send name, value.to_s
                #   end
                #   xml.Units (imperial ? 'IN' : 'CM')
                # }
              }
            end

            if !!@options[:notifications]
              xml.SpecialServicesRequested {
                xml.SpecialServiceTypes "EMAIL_NOTIFICATION"
                xml.EmailNotificationDetail {
                  xml.PersonalMessage # Personal Message to be sent to all recipients
                  @options[:notifications].each do |email|
                    xml.Recipients {
                      xml.EmailAddress email.address
                      xml.NotificationEventsRequested {
                        xml.EmailNotificationEventType{
                          xml.ON_DELIVERY  if email.on_delivery
                          xml.ON_EXCEPTION if email.on_exception
                          xml.ON_SHIPMENT  if email.on_shipment
                          xml.ON_TENDER    if email.on_tender
                        }
                      }
                      xml.Format email.format || "HTML" # options are "HTML" "Text" "Wireless"
                      xml.Localization {
                        xml.Language email.language || "EN" # Default to EN (English)
                        xml.LocaleCode email.locale_code if !email.locale_code.nil?
                      }
                    }
                  end
                  xml.EMailNotificationAggregationType @options[:notification_aggregation_type] if @options.has_key?(:notification_aggregation_type)
                }
              }
            end
          }
        }
      end
      builder.to_xml
    end

    def build_delete_request(tracking_number, shipment_type, options={})
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.DeleteShipmentRequest('xmlns' => 'http://fedex.com/ws/ship/v12') {
          build_access_request(xml)
          xml.Version {
            xml.ServiceId "ship"
            xml.Major "12"
            xml.Intermediate "0"
            xml.Minor "0"
          }
          xml.ShipTimestamp options[:ship_timestamp] if options[:ship_timestamp]
          xml.TrackingId {
            xml.TrackingIdType shipment_type
            xml.TrackingNumber tracking_number
          }
          xml.DeletionControl options[:deletion_type] || "DELETE_ALL_PACKAGES"
        }
      end
      builder.to_xml
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

    def build_access_request(xml)
      xml.WebAuthenticationDetail {
        xml.UserCredential {
          xml.Key @options[:key]
          xml.Password @options[:password]
        }
      }

      xml.ClientDetail {
        xml.AccountNumber @options[:account]
        xml.MeterNumber @options[:meter]
      }

      xml.TransactionDetail {
        xml.CustomerTransactionId 'Omniship' # TODO: Need to do something better with this...
      }
    end

    def build_location_node(name, location, xml)
      for name in name
        xml.send(name) {
          xml.Contact {
            xml.PersonName location.name unless location.name == "" || location.name == nil
            xml.CompanyName location.company unless location.company == "" || location.name == nil
            xml.PhoneNumber location.phone
          }
          xml.Address {
            xml.StreetLines location.address1
            xml.StreetLines location.address2 unless location.address2.nil?
            xml.City location.city
            xml.StateOrProvinceCode location.state
            xml.PostalCode location.postal_code
            xml.CountryCode location.country_code(:alpha2)
            xml.Residential true unless location.commercial?
          }
        }
      end
    end

    def parse_rate_response(origin, destination, packages, response, options)
      rate_estimates   = []
      success, message = nil

      xml = Nokogiri::XML(response).remove_namespaces!

      success = response_success?(xml)
      message = response_message(xml)


      service_code         = xml.xpath('//ServiceType').text == options[:service_type]
      is_saturday_delivery = xml.xpath('//AppliedOptions').text == 'SATURDAY_DELIVERY'
      service_type         = is_saturday_delivery ? "#{service_code}_SATURDAY_DELIVERY" : service_code

      currency = handle_uk_currency(xml.xpath('//RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Currency').text)
      rate_estimates << RateEstimate.new(origin, destination, @@name,
                          self.class.service_name_for_code(service_type),
                          :service_code   => service_code,
                          :total_price    => xml.xpath('//RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Amount').text.to_f,
                          :currency       => currency,
                          :packages       => packages,
                          :delivery_range => [xml.xpath('//DeliveryTimestamp').text] * 2)


      if rate_estimates.empty?
        success = false
        message = "No shipping rates could be found for the destination address" if message.blank?
      end

      RateResponse.new(success, message, Hash.from_xml(response), :rates => rate_estimates, :xml => response, :request => last_request, :log_xml => options[:log_xml])
    end

    def parse_ship_response(response, options)
      xml             = Nokogiri::XML(response).remove_namespaces!
      success         = response_success?(xml)
      message         = response_message(xml)
      label           = nil
      tracking_number = nil

      if success
        label           = xml.xpath("//Image").text
        tracking_number = xml.xpath("//TrackingNumber").text
      else
        success = false
        message = "Shipment was not succcessful." if message.blank?
      end
      ShipResponse.new(success, message, :tracking_number => tracking_number, :label_encoded => label)
    end

    def parse_delete_response(response, options={})
      xml     = Nokogiri::XML(response).remove_namespaces!
      success = response_success?(xml)
      message = response_message(xml)
      return [success, message]
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
        :xml             => response,
        :request         => last_request,
        :shipment_events => shipment_events,
        :destination     => destination,
        :tracking_number => tracking_number
      )
    end

    def response_status_node(xml)
      xml.ProcessShipmentReply
    end

    def response_success?(xml)
      %w{SUCCESS WARNING NOTE}.include? xml.xpath('//Notifications/Severity').text
    end

    def response_message(xml)
      "#{xml.xpath('//Notifications/Severity').text} - #{xml.xpath('//Notifications/Code').text}: #{xml.xpath('//Notifications/Message').text}"
    end

    def commit(request, test = false)
      ssl_post(test ? TEST_URL : LIVE_URL, request)
    end

    def handle_uk_currency(currency)
      currency =~ /UKL/i ? 'GBP' : currency
    end
  end
end
