# frozen_string_literal: true

require "marc"
require "marc/xmlreader"
require "oai"
require "rsolr"
require "stringio"
require "date"
require "oai_solr/dublin_core"

module OAISolr
  class Record
    attr_accessor :solr_document

    # @param [Hash] solr_document Hash representation of the solr document
    def initialize(solr_document)
      @solr_document = solr_document
    end

    # @return [DateTime] date/time it was last indexed
    def last_indexed
      DateTime.parse(solr_value("time_of_index"))
    end

    # TODO: Make this actually work the way we want it.
    def to_oai_dc
      OAISolr::DublinCore.instance.encode(nil, self)
    end

    # TODO: Think about just storing the marc-in-json hash; trading the increase in the size of the solr
    # directory for ease/speed here
    # @return [MARC::Record]
    def marc_record
      @record ||= MARC::XMLReader.new(StringIO.new(solr_document["fullrecord"]), parser: "nokogiri").first
    end

    def deleted?
      solr_value("deleted")
    end

    # @param [String] field Name of the field
    # @return [String, Numeric, NilClass] The found value, or nil if not found
    def solr_value(field)
      solr_document.has_key?(field) ? solr_document[field] : nil
    end

    # @param [String] field Name of the field
    # @return [Array<String>, Numeric, NilClass] The found value, or nil if not found
    def solr_array(field)
      val = solr_value(field)
      case val
      when nil, ""
        []
      when Array
        val
      else Array(val)
      end
    end

    def id
      solr_document["id"]
    end

    def updated_at
      if (ht_id_update = solr_value("ht_id_update"))
        Date.parse(ht_id_update.max.to_s).to_time
      else
        last_indexed.to_time
      end
    end
  end
end
