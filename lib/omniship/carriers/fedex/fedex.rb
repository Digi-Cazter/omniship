module Omniship
  class FedEx < Carriers::Base
    include FedExServices::Rate
    include FedExServices::Track

    TEST_URL = 'https://gatewaybeta.fedex.com:443/xml'
    LIVE_URL = 'https://gateway.fedex.com:443/xml'

    SERVICE_TYPES            = %w(EUROPE_FIRST_INTERNATIONAL_PRIORITY FEDEX_1_DAY_FREIGHT FEDEX_2_DAY FEDEX_2_DAY_AM FEDEX_2_DAY_FREIGHT FEDEX_3_DAY_FREIGHT FEDEX_EXPRESS_SAVER FEDEX_FIRST_FREIGHT FEDEX_FREIGHT_ECONOMY FEDEX_FREIGHT_PRIORITY FEDEX_GROUND FIRST_OVERNIGHT GROUND_HOME_DELIVERY INTERNATIONAL_ECONOMY INTERNATIONAL_ECONOMY_FREIGHT INTERNATIONAL_FIRST INTERNATIONAL_PRIORITY INTERNATIONAL_PRIORITY_FREIGHT PRIORITY_OVERNIGHT SMART_POST STANDARD_OVERNIGHT)
    CARRIER_CODES            = %w(FDXC FDXE FDXG FDCC FXFR FXSP)
    PACKAGING_TYPES          = %w(FEDEX_10KG_BOX FEDEX_25KG_BOX FEDEX_BOX FEDEX_ENVELOPE FEDEX_PAK FEDEX_TUBE YOUR_PACKAGING)
    DROP_OFF_TYPES           = %w(BUSINESS_SERVICE_CENTER DROP_BOX REGULAR_PICKUP REQUEST_COURIER STATION)
    CLEARANCE_BROKERAGE_TYPE = %w(BROKER_INCLUSIVE BROKER_INCLUSIVE_NON_RESIDENT_IMPORTER BROKER_SELECT BROKER_SELECT_NON_RESIDENT_IMPORTER BROKER_UNASSIGNED)
    RECIPIENT_CUSTOM_ID_TYPE = %w(COMPANY INDIVIDUAL PASSPORT)
    PAYMENT_TYPE             = %w(RECIPIENT SENDER THIRD_PARTY)
    LANGUAGE_CODES           = {
      "AR"    => "Arabic",
      "CS"    => "Czech",
      "DA"    => "Danish",
      "DE"    => "German",
      "EN"    => "English",
      "ES_ES" => "Spanish (Latin American)",
      "ES_US" => "Spanish (North America)",
      "FI"    => "Finish",
      "FR"    => "French (Europe)",
      "FR_CA" => "French (Canada)",
      "HU"    => "Hungarian",
      "IT"    => "Italian",
      "JA"    => "Kanji (Japan)",
      "KO"    => "Korean",
      "NO"    => "Norwegian",
      "NL"    => "Dutch",
      "PL"    => "Polish",
      "PT"    => "Portuguese (Latin America)",
      "RU"    => "Russian",
      "SV"    => "Swedish",
      "TR"    => "Turkish",
      "ZH_CN" => "Chinese (simplified)",
      "ZH_TW" => "Chinese (Taiwan)",
      "ZH_HK" => "Chinese (Hong Kong)"
    }

    def required_params
      [:key, :account, :meter, :password]
    end

    def initialize(options={})
      super
      if @options.has_key?(:language_code)
        raise Error.new("Invalid language code") unless LANGUAGE_CODES.keys.include?(@options[:language_code])
        if @options[:language_code].include?("_")
          @options[:locale_code] = @options[:language_code].split("_")[1]
          @options[:language_code] = @options[:language_code].split("_")[0]
        end
      end
    end

    private

    # def add_authentication_detail(xml)
    #   xml.WebAuthenticationDetail {
    #     xml.UserCredential {
    #       xml.Key @options[:key]
    #       xml.Password @options[:password]
    #     }
    #   }
    # end

    # def add_client_detail(xml)
    #   xml.ClientDetail {
    #     xml.AccountNumber @options[:account]
    #     xml.MeterNumber @options[:meter]
    #     xml.Localization {
    #       xml.LanguageCode @options[:language_code] || "EN"
    #       if @options.has_key?(:locale_code)
    #         xml.LocaleCode @options[:locale_code]
    #       end
    #     }
    #   }
    # end

    # def add_version(xml)
    #   xml.Version {
    #     xml.ServiceId service[:id]
    #     xml.Major service[:version]
    #     xml.Intermediate 0
    #     xml.Minor 0
    #   }
    # end

    # def add_shipper(xml)
    #   xml.Shipper {
    #     xml.Contact {
    #       xml.PersonName @shipper[:name]
    #       xml.CompanyName @shipper[:company]
    #       xml.PhoneNumber @shipper[:phone_number]
    #     }
    #     xml.Address {
    #       Array(@shipper[:address]).take(2).each do |address_line|
    #         xml.StreetLines address_line
    #       end
    #       xml.City @shipper[:city]
    #       xml.StateOrProvinceCode @shipper[:state]
    #       xml.PostalCode @shipper[:postal_code]
    #       xml.CountryCode @shipper[:country_code]
    #     }
    #   }
    # end

    # def add_recipient(xml)
    #   xml.Recipient {
    #     xml.Contact {
    #       xml.PersonName @recipient[:name]
    #       xml.CompanyName @recipient[:company]
    #       xml.PhoneNumber @recipient[:phone_number]
    #     }
    #     xml.Address {
    #       Array(@recipient[:address]).take(2).each do |address_line|
    #         xml.StreetLines address_line
    #       end
    #       xml.City @recipient[:city]
    #       xml.StateOrProvinceCode @recipient[:state]
    #       xml.PostalCode @recipient[:postal_code]
    #       xml.CountryCode @recipient[:country_code]
    #       xml.Residential @recipient[:residential]
    #     }
    #   }
    # end

    # def add_packages(xml)
    #   add_master_tracking_id(xml) if @mps.has_key? :master_tracking_id
    #   package_count = @packages.size
    #   if @mps.has_key? :package_count
    #     xml.PackageCount @mps[:package_count]
    #   else
    #     xml.PackageCount package_count
    #   end
    #   @packages.each do |package|
    #     xml.RequestedPackageLineItems {
    #       if @mps.has_key? :sequence_number
    #         xml.SequenceNumber @mps[:sequence_number]
    #       else
    #         xml.GroupPackageCount 1
    #       end
    #       if package[:insured_value]
    #         xml.InsuredValue {
    #           xml.Currency package[:insured_value][:currency]
    #           xml.Amount package[:insured_value][:amount]
    #         }
    #       end
    #       xml.Weight {
    #         xml.Units package[:weight][:units]
    #         xml.Value package[:weight][:value]
    #       }
    #       if package[:dimensions]
    #         xml.Dimensions {
    #           xml.Length package[:dimensions][:length]
    #           xml.Width package[:dimensions][:width]
    #           xml.Height package[:dimensions][:height]
    #           xml.Units package[:dimensions][:units]
    #         }
    #       end
    #       add_customer_references(xml, package)
    #       if package[:special_services_requested] && package[:special_services_requested][:special_service_types]
    #         xml.SpecialServicesRequested {
    #           if package[:special_services_requested][:special_service_types].is_a? Array
    #             package[:special_services_requested][:special_service_types].each do |type|
    #               xml.SpecialServiceTypes type
    #             end
    #           else
    #             xml.SpecialServiceTypes package[:special_services_requested][:special_service_types]
    #           end
    #           # Handle COD Options
    #           if package[:special_services_requested][:cod_detail]
    #             xml.CodDetail {
    #               xml.CodCollectionAmount {
    #                 xml.Currency package[:special_services_requested][:cod_detail][:cod_collection_amount][:currency]
    #                 xml.Amount package[:special_services_requested][:cod_detail][:cod_collection_amount][:amount]
    #               }
    #               if package[:special_services_requested][:cod_detail][:add_transportation_charges]
    #                 xml.AddTransportationCharges package[:special_services_requested][:cod_detail][:add_transportation_charges]
    #               end
    #               xml.CollectionType package[:special_services_requested][:cod_detail][:collection_type]
    #               xml.CodRecipient {
    #                 add_shipper(xml)
    #               }
    #               if package[:special_services_requested][:cod_detail][:reference_indicator]
    #                 xml.ReferenceIndicator package[:special_services_requested][:cod_detail][:reference_indicator]
    #               end
    #             }
    #           end
    #           # DangerousGoodsDetail goes here
    #           if package[:special_services_requested][:dry_ice_weight]
    #             xml.DryIceWeight {
    #               xml.Units package[:special_services_requested][:dry_ice_weight][:units]
    #               xml.Value package[:special_services_requested][:dry_ice_weight][:value]
    #             }
    #           end
    #           if package[:special_services_requested][:signature_option_detail]
    #             xml.SignatureOptionDetail {
    #               xml.OptionType package[:special_services_requested][:signature_option_detail][:signature_option_type]
    #             }
    #           end
    #           if package[:special_services_requested][:priority_alert_detail]
    #             xml.PriorityAlertDetail package[:special_services_requested][:priority_alert_detail]
    #           end
    #         }
    #       end
    #     }
    #   end
    # end

    # def api_url
    #   @test ? TEST_URL : LIVE_URL
    # end

    # def response_success?(xml)
    #   %w{SUCCESS WARNING NOTE}.include? xml.xpath('//Notifications/Severity').text
    # end

    # def response_message(xml)
    #   "#{xml.xpath('//Notifications/Severity').text} - #{xml.xpath('//Notifications/Code').text}: #{xml.xpath('//Notifications/Message').text}"
    # end

    # def commit(request)
    #   ssl_post(api_url, request)
    # end
  end
end
