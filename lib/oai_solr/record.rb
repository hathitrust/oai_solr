# frozen_string_literal: true

require "marc"
require "marc/xmlreader"
require "oai"
require "rsolr"
require "stringio"
require "date"

module OAISolr
  class Record
    attr_accessor :solr_document, :dc_hash

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
      DublinCore.instance.encode(nil, self)
    end

    #     # this is an alternative to using to_oai_dc and our DublinCore class
    #     # It relies on on OAI::Provider::Metadata::Format to use the built in
    #     # DublinCore format and record.respond_to?.
    #     # Both approaches result in an invalid OAI response
    #     def dc_hash
    #       @dc_hash ||= marc_record.to_dublin_core
    #     end
    #
    #     [:title, :creator, :subject, :description, :publisher, :date, :type, :format, :identifier, :source, :language, :relation, :coverage, :rights].each do |dc_attr|
    #       define_method dc_attr do
    #         dc_hash[dc_attr.to_s] || []
    #       end
    #     end

    # TODO: Think about just storing the marc-in-json hash; trading the increase in the size of the solr
    # directory for ease/speed here
    # @return [MARC::Record]
    def marc_record
      @record ||= MARC::XMLReader.new(StringIO.new(solr_document["fullrecord"])).first
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
      Date.parse(solr_document["ht_id_update"].max.to_s).to_time
    end
  end
end
