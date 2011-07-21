module Importer
  class ImmunizationImporter < QME::Importer::SectionImporter
    def initialize
      @entry_xpath = "//cda:section[cda:templateId/@root='2.16.840.1.113883.3.88.11.83.117']/cda:entry/cda:substanceAdministration"
      @code_xpath = "./cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:code"
      @description_xpath = "./cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:originalText/cda:reference[@value]"
      @check_for_usable = true               # Pilot tools will set this to false
      @id_map = {}
    end
    
    # Traverses that HITSP C32 document passed in using XPath and creates an Array of Entry
    # objects based on what it finds                          
    # @param [Nokogiri::XML::Document] doc It is expected that the root node of this document
    #        will have the "cda" namespace registered to "urn:hl7-org:v3"
    #        measure definition
    # @return [Array] will be a list of Entry objects
    def create_entries(doc,id_map = {})
      @id_map = id_map
      immunization_list = []
      entry_elements = doc.xpath(@entry_xpath)
      entry_elements.each do |entry_element|
        immunization = Immunization.new
        extract_codes(entry_element, immunization)
        extract_dates(entry_element, immunization)
        extract_description(entry_element, immunization, id_map)
        extract_refusal(entry_element, immunization)
        if @check_for_usable
          immunization_list << immunization if immunization.usable?
        else
          immunization_list << immunization
        end
      end
      immunization_list
    end
    
    private
    def extract_refusal(parent_element, immunization)
      negation_indicator = parent_element['negationInd']
      unless negation_indicator.nil?
        immunization.refusal = negation_indicator.eql?('true')
      end
    end
  end
end