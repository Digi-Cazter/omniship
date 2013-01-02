module Omniship
  class UPS < Carrier
    self.retry_safe = true

    cattr_accessor :default_options
    cattr_reader :name
    @@name = "UPS"

    TEST_URL = 'https://wwwcie.ups.com'
    LIVE_URL = 'https://onlinetools.ups.com'

    RESOURCES = {
        :rates => 'ups.app/xml/Rate',
        :track => 'ups.app/xml/Track',
        :shipconfirm => 'ups.app/xml/ShipConfirm',
        :shipaccept => 'ups.app/xml/ShipAccept',
        :shipvoid => 'ups.app/xml/Void',
        :valid_address => 'ups.app/xml/XAV'
    }

    PICKUP_CODES = HashWithIndifferentAccess.new({
                                                     :daily_pickup => "01",
                                                     :customer_counter => "03",
                                                     :one_time_pickup => "06",
                                                     :on_call_air => "07",
                                                     :suggested_retail_rates => "11",
                                                     :letter_center => "19",
                                                     :air_service_center => "20"
                                                 })

    CUSTOMER_CLASSIFICATIONS = HashWithIndifferentAccess.new({
                                                                 :wholesale => "01",
                                                                 :occasional => "03",
                                                                 :retail => "04"
                                                             })

    # these are the defaults described in the UPS API docs,
    # but they don't seem to apply them under all circumstances,
    # so we need to take matters into our own hands
    DEFAULT_CUSTOMER_CLASSIFICATIONS = Hash.new do |hash, key|
      hash[key] = case key.to_sym
                    when :daily_pickup then
                      :wholesale
                    when :customer_counter then
                      :retail
                    else
                      :occasional
                  end
    end

    DEFAULT_SERVICES = {
        "01" => "UPS Next Day Air",
        "02" => "UPS Second Day Air",
        "03" => "UPS Ground",
        "07" => "UPS Worldwide Express",
        "08" => "UPS Worldwide Expedited",
        "11" => "UPS Standard",
        "12" => "UPS Three-Day Select",
        "13" => "UPS Next Day Air Saver",
        "14" => "UPS Next Day Air Early A.M.",
        "54" => "UPS Worldwide Express Plus",
        "59" => "UPS Second Day Air A.M.",
        "65" => "UPS Saver",
        "82" => "UPS Today Standard",
        "83" => "UPS Today Dedicated Courier",
        "84" => "UPS Today Intercity",
        "85" => "UPS Today Express",
        "86" => "UPS Today Express Saver"
    }

    CANADA_ORIGIN_SERVICES = {
        "01" => "UPS Express",
        "02" => "UPS Expedited",
        "14" => "UPS Express Early A.M."
    }

    MEXICO_ORIGIN_SERVICES = {
        "07" => "UPS Express",
        "08" => "UPS Expedited",
        "54" => "UPS Express Plus"
    }

    EU_ORIGIN_SERVICES = {
        "07" => "UPS Express",
        "08" => "UPS Expedited"
    }

    OTHER_NON_US_ORIGIN_SERVICES = {
        "07" => "UPS Express"
    }

    # From http://en.wikipedia.org/w/index.php?title=European_Union&oldid=174718707 (Current as of November 30, 2007)
    EU_COUNTRY_CODES = ["GB", "AT", "BE", "BG", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]

    US_TERRITORIES_TREATED_AS_COUNTRIES = ["AS", "FM", "GU", "MH", "MP", "PW", "PR", "VI"]

    def requirements
      [:key, :login, :password]
    end

    def find_rates(origin, destination, packages, options={})
      origin, destination = upsified_location(origin), upsified_location(destination)
      options = @options.merge(options)
      options[:test] = options[:test].nil? ? false : options[:test]
      packages = Array(packages)
      access_request = build_access_request
      rate_request = build_rate_request(origin, destination, packages, options)
      response = commit(:rates, save_request(access_request.gsub("\n", "") + rate_request.gsub("\n", "")), options[:test])
      parse_rate_response(origin, destination, packages, response, options)
    end

    def find_tracking_info(tracking_number, options={})
      options = @options.update(options)
      options[:test] = options[:test].nil? ? false : options[:test]
      access_request = build_access_request
      tracking_request = build_tracking_request(tracking_number, options)
      response = commit(:track, save_request(access_request.gsub("\n", "") + tracking_request.gsub("\n", "")), options[:test])
      parse_tracking_response(response, options)
    end

    # Creating shipping functionality for UPS
    def create_shipment(origin, destination, packages, options={})
      @options = @options.merge(options)
      origin, destination = upsified_location(origin), upsified_location(destination)
      options = @options.merge(options)
      options[:test] = options[:test].nil? ? true : options[:test]
      packages = Array(packages)
      access_request = build_access_request
      ship_confirm_request = build_ship_confirm(origin, destination, packages, options)
      response = commit(:shipconfirm, save_request(access_request.gsub("\n", "") + ship_confirm_request.gsub("\n", "")), options[:test])
      parse_ship_confirm_response(origin, destination, packages, response, options)
    end

    def accept_shipment(digest, options={})
      options[:test] = options[:test].nil? ? true : options[:test]
      access_request = build_access_request
      ship_accept_request = build_ship_accept(digest)
      response = commit(:shipaccept, save_request(access_request.gsub("\n", "") + ship_accept_request.gsub("\n", "")), options[:test])
      parse_ship_accept_response(response, options)
    end

    def void_shipment(ups_shipment_id,tracking_number, options={})
      @options = @options.merge(options)
      options = @options.merge(options)
      options[:test] = options[:test].nil? ? true : options[:test]
      access_request = build_access_request
      ship_void_request = build_void_request(ups_shipment_id,tracking_number)
      response = commit(:shipvoid, save_request(access_request.gsub("\n", "") + ship_void_request.gsub("\n", "")), options[:test])
      parse_ship_void_response(response, options)
    end
    
    def validate_address(address,city,state,zip_code,country_code, options={})
      @options = @options.merge(options)
      access_request = build_access_request
      validate_address_request = build_valid_address_request(address,city,state,zip_code,country_code)
      options[:test] = options[:test].nil? ? true : options[:test]
      response = commit(:valid_address, save_request(access_request.gsub("\n", "") + validate_address_request.gsub("\n", "")), options[:test])
      parse_response = parse_ship_valid_address(response)
      parse_response
    end

    protected

    def upsified_location(location)
      if location.country_code == 'US' && US_TERRITORIES_TREATED_AS_COUNTRIES.include?(location.state)
        atts = {:country => location.state}
        [:zip, :city, :address1, :address2, :address3, :phone, :fax, :address_type, :attention_name].each do |att|
          atts[att] = location.send(att)
        end
        Address.new(atts)
      else
        location
      end
    end
        

    def build_access_request
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.AccessRequest {
          xml.AccessLicenseNumber @options[:key].nil? ? @config['ups']['key'] : @options[:key]
          xml.UserId @options[:login].nil? ? @config['ups']['username'] : @options[:login]
          xml.Password @options[:password].nil? ? @config['ups']['password'] : @options[:password]


          xml.AccessLicenseNumber @config['ups']['key'] unless @options[:key]
          xml.UserId @config['ups']['username'] unless @options[:login]
          xml.Password @config['ups']['password'] unless @options[:password]
        }
      end
      builder.to_xml
    end

    # Build the ship_confirm XML request      
    def build_ship_confirm(origin, destination, packages, options={})

      #Return Service types:
      #‘2’ = UPS Print and Mail (PNM)
      #‘3’ = UPS Return Service 1- Attempt (RS1)
      #‘5’ = UPS Return Service 3-Attempt (RS3)
      #‘8’ = UPS Electronic Return Label (ERL)
      #‘9’ = UPS Print Return Label (PRL)


      packages = Array(packages)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.ShipmentConfirmRequest {
          xml.Request {
            xml.RequestAction 'ShipConfirm'
            xml.RequestOption 'validate'
          }
          xml.Shipment {
            build_location_node(['Shipper'], (options[:shipper] || origin), options, xml)
            build_location_node(['ShipTo'], destination, options, xml)
            if options[:shipper] && options[:shipper] != origin
              build_location_node(['ShipFrom'], origin, options, xml)
            end
            xml.PaymentInformation {
              xml.Prepaid {
                xml.BillShipper {
                  xml.AccountNumber options[:origin_account]
                }
              }
            }
            xml.Service {
              xml.Code options[:service]
            }
            xml.ShipmentServiceOptions {
              xml.SaturdayDelivery if options[:saturday] == true
              if options[:delivery_confirmation_type].present?
                xml.DeliveryConfirmation {
                  xml.DCISType options[:delivery_confirmation_type]
                }
              end
            }
            if options[:return_service_code].present?
              xml.ReturnService {
                xml.Code options[:return_service_code]
                if options[:return_service_description].present?
                  xml.Description options[:return_service_description]
                end
              }
            end
            packages.each do |package|
              imperial = ['US', 'LR', 'MM'].include?(origin.country_code(:alpha2))
              xml.Package {
                xml.PackagingType {
                  xml.Code package.options[:package_type]
                }
                xml.Dimensions {
                  xml.UnitOfMeasurement {
                    xml.Code imperial ? 'IN' : 'CM'
                  }
                  [:length, :width, :height].each do |axis|
                    value = ((imperial ? package.inches(axis) : package.cm(axis)).to_f*1000).round/1000.0 # 3 decimals
                    xml.send axis.to_s.gsub(/^[a-z]|\s+[-z]/) { |a| a.upcase }, [value, 0.1].max
                  end
                }
                xml.PackageWeight {
                  xml.UnitOfMeasurement {
                    xml.Code imperial ? 'LBS' : 'KGS'
                  }
                  value = ((imperial ? package.lbs : package.kgs).to_f*1000).round/1000.0 # decimals
                  xml.Weight [value, 0.1].max
                }
                xml.Description package.options[:package_description] if package.options[:package_description].present?
                xml.PackageServiceOptions {
                  if package.options[:delivery_confirmation_type].present?
                    xml.DeliveryConfirmation {
                      xml.DCISType package.options[:delivery_confirmation_type]
                    }
                  end
                }
              }
            end
            xml.LabelSpecification {
              xml.LabelPrintMethod {
                xml.Code 'GIF'
              }
              xml.LabelImageFormat {
                xml.Code 'PNG'
              }
            }
          }
        }
      end
      builder.to_xml
    end

    def build_ship_accept(digest)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.ShipmentAcceptRequest {
          xml.Request {
            xml.RequestAction 'ShipAccept'
          }
          xml.ShipmentDigest digest
        }
      end
      builder.to_xml
    end

    def build_void_request(ups_shipment_id,tracking_number)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.VoidShipmentRequest {
          xml.Request {
            xml.RequestAction 'Void'
          }
          xml.ExpandedVoidShipment {
            xml.ShipmentIdentificationNumber ups_shipment_id
            xml.TrackingNumber tracking_number
          }
        }
      end
      builder.to_xml
    end
    
    def build_valid_address_request(address,city,state,zip_code,country_code)
      builder = Nokogiri::XML::Builder.new do |xml|
          xml.AddressValidationRequest {
            xml.Request{
              xml.RequestAction 'XAV'
              xml.RequestOption 3
            }
            
            xml.AddressKeyFormat{
              xml.AddressLine address
              xml.PoliticalDivision2 city
              xml.PoliticalDivision1 state
              xml.PostcodePrimaryLow zip_code
              xml.CountryCode country_code
            }
          }
      end
      builder.to_xml
    end

    def build_rate_request(origin, destination, packages, options={})
      packages = Array(packages)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.RatingServiceSelectionRequest {
          xml.Request {
            xml.RequestAction 'Rate'
            xml.RequestOption 'Shop'
          }
          # not implemented: 'Rate' RequestOption to specify a single service query
          # request << XmlNode.new('RequestOption', ((options[:service].nil? or options[:service] == :all) ? 'Shop' : 'Rate'))
          pickup_type = options[:pickup_type] || :daily_pickup
          xml.PickupType {
            xml.Code PICKUP_CODES[pickup_type]
            # not implemented: PickupType/PickupDetails element
          }
          cc = options[:customer_classification] || DEFAULT_CUSTOMER_CLASSIFICATIONS[pickup_type]
          xml.CustomerClassification {
            xml.Code CUSTOMER_CLASSIFICATIONS[cc]
          }
          xml.Shipment {
            build_location_node(['Shipper'], (options[:shipper] || origin), options, xml)
            build_location_node(['ShipTo'], destination, options, xml)
            if options[:shipper] && options[:shipper] != origin
              build_location_node(['ShipFrom'], origin, options, xml)
            end

            # not implemented:  * Shipment/ShipmentWeight element
            #                   * Shipment/ReferenceNumber element
            #                   * Shipment/Service element
            #                   * Shipment/PickupDate element
            #                   * Shipment/ScheduledDeliveryDate element
            #                   * Shipment/ScheduledDeliveryTime element
            #                   * Shipment/AlternateDeliveryTime element
            #                   * Shipment/DocumentsOnly element

            packages.each do |package|
              imperial = ['US', 'LR', 'MM'].include?(origin.country_code(:alpha2))
              xml.Package {
                xml.PackagingType {
                  xml.Code '02'
                }
                xml.Dimensions {
                  xml.UnitOfMeasurement {
                    xml.Code imperial ? 'IN' : 'CM'
                  }
                  [:length, :width, :height].each do |axis|
                    value = ((imperial ? package.inches(axis) : package.cm(axis)).to_f*1000).round/1000.0 # 3 decimals
                    xml.send axis.to_s.gsub(/^[a-z]|\s+[-z]/) { |a| a.upcase }, [value, 0.1].max
                  end
                }
                xml.PackageWeight {
                  xml.UnitOfMeasurement {
                    xml.Code imperial ? 'LBS' : 'KGS'
                  }
                  value = ((imperial ? package.lbs : package.kgs).to_f*1000).round/1000.0 # 3 decimals
                  xml.Weight [value, 0.1].max
                }
                xml.PackageServiceOptions {
                  if package.options[:delivery_confirmation_type].present?
                    xml.DeliveryConfirmation {
                      xml.DCISType package.options[:delivery_confirmation_type]
                    }
                  end
                }
                # not implemented:  * Shipment/Package/LargePackageIndicator element
                #                   * Shipment/Package/ReferenceNumber element
                #                   * Shipment/Package/AdditionalHandling element
              }
            end
            # not implemented:  * Shipment/ShipmentServiceOptions element
            #                   * Shipment/RateInformation element
          }
        }
      end
      builder.to_xml
    end

    def build_tracking_request(tracking_number, options={})
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.TrackRequest {
          xml.Request {
            xml.RequestAction 'Track'
            xml.RequestOption '7'
          }          
          xml.TrackingNumber tracking_number.to_s          
          xml.TrackingOption '02'
        }
      end
      builder.to_xml
    end

    def build_location_node(name, location, options={}, xml)
      for name in name
        xml.send(name) {
          xml.Name location.name unless location.name.blank?
          xml.AttentionName location.attention_name unless location.attention_name.blank?
          xml.CompanyName location.company_name unless location.company_name.blank?
          xml.PhoneNumber location.phone.gsub(/[^\d]/, '') unless location.phone.blank?
          xml.FaxNumber location.fax.gsub(/[^\d]/, '') unless location.fax.blank?

          if name =='Shipper' and (origin_account = @options[:origin_account] || options[:origin_account])
            xml.ShipperNumber origin_account
          elsif name == 'ShipTo' and (destination_account = @options[:destination_account] || options[:destination_account])
            xml.ShipperAssignedIdentificationNumber destination_account
          end

          xml.Address {
            xml.AddressLine1 location.address1 unless location.address1.blank?
            xml.AddressLine2 location.address2 unless location.address2.blank?
            xml.AddressLine3 location.address3 unless location.address3.blank?
            xml.City location.city unless location.city.blank?
            xml.StateProvinceCode location.province unless location.province.blank?
            xml.PostalCode location.postal_code unless location.postal_code.blank?
            xml.CountryCode location.country_code unless location.country_code.blank?
            xml.ResidentialAddress unless location.commercial?
          }
        }
      end
    end

    def parse_rate_response(origin, destination, packages, response, options={})
      rates = []

      xml = Nokogiri::XML(response)
      success = response_success?(xml)
      message = response_message(xml)

      if success
        rate_estimates = []

        xml.xpath('/*/RatedShipment').each do |rated_shipment|
          service_code = rated_shipment.xpath('Service/Code').text.to_s
          days_to_delivery = rated_shipment.xpath('GuaranteedDaysToDelivery').text.to_s.to_i
          delivery_date = days_to_delivery >= 1 ? days_to_delivery.days.from_now.strftime("%Y-%m-%d") : nil

          rate_estimates << RateEstimate.new(origin, destination, @@name,
                                             service_name_for(origin, service_code),
                                             :total_price => rated_shipment.xpath('TotalCharges/MonetaryValue').text.to_s.to_f,
                                             :currency => rated_shipment.xpath('TotalCharges/CurrencyCode').text.to_s,
                                             :service_code => service_code,
                                             :packages => packages,
                                             :delivery_range => [delivery_date])
        end
      end
      RateResponse.new(success, message, Hash.from_xml(response).values.first, :rates => rate_estimates, :xml => response, :request => last_request)
    end

    def parse_tracking_response(response, options={})      
      xml = Nokogiri::XML(response)
      success = response_success?(xml)
      message = response_message(xml)
      
      puts "response :" + xml.to_s
            
      if success
        tracking_number, origin, destination = nil
        shipment_details = Hash.new
        
        tracking_number = xml.xpath('/*/Shipment/Package/TrackingNumber').text        
        estimated_delivery_date = xml.xpath('/*/Shipment/ScheduledDeliveryDate').text        
        estimated_delivery_date = Date.strptime(estimated_delivery_date,'%Y%m%d')
      
        puts 'tracking_number: ' + tracking_number
        puts 'estimated_delivery_date: ' + estimated_delivery_date.to_s  
        
        shipment_details[:tracking_number] = tracking_number
        shipment_details[:estimated_delivery_date] = estimated_delivery_date

        #first_shipment = xml.gelements['/*/Shipment']
        #first_package = first_shipment.elements['Package']
        #tracking_number = first_shipment.get_text('ShipmentIdentificationNumber | Package/TrackingNumber').to_s

        #origin, destination = %w{Shipper ShipTo}.map do |location|
        #  location_from_address_node(first_shipment.elements["#{location}/Address"])
        #end

        #activities = first_package.get_elements('Activity')
        #unless activities.empty?
        #  shipment_events = activities.map do |activity|
        #    description = activity.get_text('Status/StatusType/Description').to_s
        #    zoneless_time = if (time = activity.get_text('Time')) &&
        #                       (date = activity.get_text('Date'))
        #      time, date = time.to_s, date.to_s
        #      hour, minute, second = time.scan(/\d{2}/)
        #      year, month, day = date[0..3], date[4..5], date[6..7]
        #      Time.utc(year, month, day, hour, minute, second)
        #    end
        #    location = location_from_address_node(activity.elements['ActivityLocation/Address'])
        #    ShipmentEvent.new(description, zoneless_time, location)
        #  end
        #  
        #  shipment_events = shipment_events.sort_by(&:time)
        #  
        #  if origin
        #    first_event = shipment_events[0]
        #    same_country = origin.country_code(:alpha2) == first_event.location.country_code(:alpha2)
        #    same_or_blank_city = first_event.location.city.blank? or first_event.location.city == origin.city
        #    origin_event = ShipmentEvent.new(first_event.name, first_event.time, origin)
        #    if same_country and same_or_blank_city
        #      shipment_events[0] = origin_event
        #    else
        #      shipment_events.unshift(origin_event)
        #    end
        #  end
        #  if shipment_events.last.name.downcase == 'delivered'
        #    shipment_events[-1] = ShipmentEvent.new(shipment_events.last.name, shipment_events.last.time, destination)
        #  end
        #end
      end
      #TrackingResponse.new(success, message, Hash.from_xml(response).values.first,
      #  :xml => response,
      #  :request => last_request,
      #  :shipment_events => shipment_events,
      #  :origin => origin,
      #  :destination => destination,
      #  :tracking_number => tracking_number)
      return shipment_details
    end

    def parse_ship_confirm_response(origin, destination, packages, response, options={})
      xml = Nokogiri::XML(response)
      success = response_success?(xml)

      if success
        @response_text = xml.xpath('//*/ShipmentDigest').text
      else
        @response_text = {}
        @response_text[:status] = xml.xpath('/*/Response/ResponseStatusDescription').text
        @response_text[:error_severity] = xml.xpath('/*/Response/Error/ErrorSeverity').text
        @response_text[:error_code] = xml.xpath('/*/Response/Error/ErrorCode').text
        @response_text[:error_description] = xml.xpath('/*/Response/Error/ErrorDescription').text
      end
      return @response_text
    end

    def parse_ship_accept_response(response, options={})
      xml = Nokogiri::XML(response)
      success = response_success?(xml)
      @response_text = {}

      if success
        tracking_number = []
        label = []

        @response_text[:charges] = xml.xpath('/*/ShipmentResults/*/TotalCharges/MonetaryValue').text
        @response_text[:shipment_id] = xml.xpath('/*/ShipmentResults/ShipmentIdentificationNumber').text

        xml.xpath('/*/ShipmentResults/*/TrackingNumber').each do |track|
          tracking_number << track.text
        end
        @response_text[:tracking_number] = tracking_number

        xml.xpath('/*/ShipmentResults/*/LabelImage/GraphicImage').each do |image|
          label << image.text
        end
        @response_text[:label] = label
        @response_text[:success] = true
      else
        @response_text[:status] = xml.xpath('/*/Response/ResponseStatusDescription').text
        @response_text[:error_severity] = xml.xpath('/*/Response/Error/ErrorSeverity').text
        @response_text[:error_code] = xml.xpath('/*/Response/Error/ErrorCode').text
        @response_text[:error_description] = xml.xpath('/*/Response/Error/ErrorDescription').text
      end
      return @response_text
    end

    def parse_ship_void_response(response, options={})
      xml = Nokogiri::XML(response)
      puts "Void response: " + xml.to_s
      success = response_success?(xml)
      if success
        @void = "Shipment successfully voided!"
      else
        @void = "Voiding shipment failed!"
      end

      return @void
    end
    
    def parse_ship_valid_address(response, options={})
      xml = Nokogiri::XML(response)
      success = response_success?(xml)
      suggested_addresses = Array.new
      if success
        addresses = xml.xpath('/*/AddressKeyFormat').each do |address_data|
          address_hash = Hash.new
          address_hash[:address] = address_data.xpath('AddressLine').text
          address_hash[:city] = address_data.xpath('PoliticalDivision2').text
          address_hash[:state] = address_data.xpath('PoliticalDivision1').text
          address_hash[:zip_code] = address_data.xpath('PostcodePrimaryLow').text
          address_hash[:country_code] = address_data.xpath('CountryCode').text
          suggested_addresses << address_hash
        end
      else
        return "Address validation failed!"
      end

      return suggested_addresses
    end

    def location_from_address_node(address)
      return nil unless address
      Address.new(
          :country => node_text_or_nil(address.elements['CountryCode']),
          :postal_code => node_text_or_nil(address.elements['PostalCode']),
          :province => node_text_or_nil(address.elements['StateProvinceCode']),
          :city => node_text_or_nil(address.elements['City']),
          :address1 => node_text_or_nil(address.elements['AddressLine1']),
          :address2 => node_text_or_nil(address.elements['AddressLine2']),
          :address3 => node_text_or_nil(address.elements['AddressLine3'])
      )
    end

    def response_success?(xml)
      xml.xpath('/*/Response/ResponseStatusCode').text == '1'
    end

    def response_message(xml)
      xml.xpath('/*/Response/Error/ErrorDescription | /*/Response/ResponseStatusDescription').text
    end

    def commit(action, request, test = false)
      ssl_post("#{test ? TEST_URL : LIVE_URL}/#{RESOURCES[action]}", request)
    end


    def service_name_for(origin, code)
      origin = origin.country_code(:alpha2)

      name = case origin
               when "CA" then
                 CANADA_ORIGIN_SERVICES[code]
               when "MX" then
                 MEXICO_ORIGIN_SERVICES[code]
               when *EU_COUNTRY_CODES then
                 EU_ORIGIN_SERVICES[code]
             end

      name ||= OTHER_NON_US_ORIGIN_SERVICES[code] unless name == 'US'
      name ||= DEFAULT_SERVICES[code]
    end

  end
end
