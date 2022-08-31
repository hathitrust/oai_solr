# frozen_string_literal: true

require "oai_solr/record"
require "oai_solr/set"

module OAISolr
  class PartialResult
    def self.new_from_solr_response(response, opts)
      new(solr_response: response, opts: opts)
    end

    def initialize(solr_response:, opts:)
      @response = solr_response
      @opts = opts
      @set = OAISolr::Set.for_spec(opts[:set])
    end

    def records
      @response["response"]["docs"].map { |doc| OAISolr::Record.new(prune_doc(doc)) }
    end

    def token
      OAI::Provider::ResumptionToken.new(
        @opts.merge(last: @response["nextCursorMark"]),
        nil,
        @response["response"]["numFound"]
      )
    end

    private

    # Remove 974 datafield for any HT volumes that do not belong in the set, if any.
    # Note: this is a hack that modifies the SOLR record in place before passing it to
    # OAISolr::Record. A better approach might be to alter the OAISolr::Record after it
    # is created, in a way that doesn't require it to keep track of what set it is
    # supposed to belong to, perhaps be telling it to jettison certain subfields.
    def prune_doc(doc)
      xpath = @set.filter_xpath
      return doc if xpath.nil?

      xml = Nokogiri::XML::Document.parse(doc["fullrecord"])
      nodes = xml.xpath(xpath)
      nodes.each { |node| node.parent.remove }
      doc["fullrecord"] = xml.to_xml
      doc
    end
  end
end
