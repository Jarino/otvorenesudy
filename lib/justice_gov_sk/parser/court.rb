# encoding: utf-8

module JusticeGovSk
  module Parser
    class Court < JusticeGovSk::Parser
      def type(document)
        name(document).split(/\s/).first
      end
      
      def municipality_name(document)
        find_value_by_group_and_index 'municipality name', document, 'Kontakt', 3 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.municipality_name(div.text)
        end
      end
      
      def municipality_zipcode(document)
        find_value_by_group_and_index 'municipality zipcode', document, 'Kontakt', 2 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.zipcode(div.text)
        end
      end
      
      def name(document)
        @name ||= find_value_by_group_and_index 'name', document, 'Kontakt', 0 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.court_name(div.text)
        end
      end
      
      def street(document)
        find_value_by_group_and_index 'street', document, 'Kontakt', 1 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.street(div.text)
        end
      end
      
      def phone(document)
        find_value_by_group_and_index 'phone', document, 'Kontakt', 4 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.phone(div.text)
        end
      end
     
      def fax(document)
        find_value_by_group_and_index 'fax', document, 'Kontakt', 5 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.phone(div.text)
        end
      end
      
      def media_person(document)
        @media_person ||= find_value_by_group_and_index 'media person', document, 'Kontakt pre médiá', 0, verbose: false do |div|
          {
            name:             JusticeGovSk::Helpers::NormalizeHelper.person_name(div.text),
            name_unprocessed: div.text.strip
          }
        end
      end
      
      def media_phone(document)
        find_value_by_group_and_index 'media phone', document, 'Kontakt pre médiá', 1 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.phone(div.text)
        end 
      end
      
      def office_phone(type, document)
        find_value_by_group_and_index office_type_to_name(type) + ' phone', document, office_type_to_group(type), 0 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.phone(div.text)
        end         
      end

      def office_email(type, document)
        find_value_by_group_and_index office_type_to_name(type) + ' email', document, office_type_to_group(type), 1 do |div|
          JusticeGovSk::Helpers::NormalizeHelper.email(div.text)
        end                 
      end

      def office_hours(type, document)
        group = office_type_to_group(type)
        name  = office_type_to_name(type)
        
        hours = {
          monday:    office_daily_hours(name + ' monday hours',    document, group, 3),
          tuesday:   office_daily_hours(name + ' tuesday hours',   document, group, 4),
          wednesday: office_daily_hours(name + ' wednesday hours', document, group, 5),
          thursday:  office_daily_hours(name + ' thursday hours',  document, group, 6),
          friday:    office_daily_hours(name + ' friday hours',    document, group, 7)
        }
        
        hours.values.each { |value| return hours unless value.nil? }
        
        nil
      end
      
      def office_note(type, document)
        find_value_by_group_and_index office_type_to_name(type) + ' note', document, office_type_to_group(type), 2 do |div|
          div.text.strip.squeeze(' ')
        end         
      end
      
      def latitude(document)
        coordinates(document)[:latitude]
      end
      
      def longitude(document)
        coordinates(document)[:longitude]
      end
      
      protected
      
      def clear_caches
        super
        
        @name         = nil
        @media_person = nil
        @coordinates  = nil
      end
      
      private
      
      def office_type_to_group(type)
        case type 
        when :information_center
            'Informačné centrum'
        when :registry_center
            'Podateľňa'
        when :business_registry_center
            'Informačné stredisko obchodného registra'
        end
      end
      
      def office_type_to_name(type)
        type.to_s.gsub(/\_/, ' ')
      end
      
      def office_daily_hours(name, document, group, index)
        find_value_by_group_and_index name, document, group, index do |div|
           JusticeGovSk::Helpers::NormalizeHelper.hours(div.text)
        end
      end
      
      def coordinates(document)
        @coordinates ||= find_value 'coordinates', document, 'div.textInfo iframe', empty?: false, verbose: false do |iframe|
          data   = iframe.first[:src].scan(/(\&|s)ll=(\-?\d+\.\d+)\,(\-?\d+\.\d+)/)
          values = data.select { |v| v.first == '&' }.first
          values = data.first if values.blank?
          
          { latitude: values[1], longitude: values[2] }
        end
      end
    end
  end
end