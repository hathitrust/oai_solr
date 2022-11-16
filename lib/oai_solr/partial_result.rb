# frozen_string_literal: true

require "oai_solr/record"
require "oai_solr/set"
require "nokogiri"

module OAISolr
  class PartialResult
    def self.new_from_solr_response(response, opts)
      new(solr_response: response, opts: opts)
    end

    # @param [Hash] solr_response Full response from the solr query (parsed from the JSON)
    # @option opts [String] :set set key (as seen in settings.yml)
    # @todo make a real options object?
    def initialize(solr_response:, opts:)
      @response = solr_response
      @opts = opts
      @set = OAISolr::Set.for_spec(opts[:set])
    end

    # @return [Array<OAISolr::Record>] Records from the response that fit the set criteria,
    #   possibly munged to remove some fields
    def records
      @response["response"]["docs"]
        .map { |doc| OAISolr::Record.new(doc) }
        .map { |rec| @set.remove_unwanted_974s(rec) }
        .select { |rec| @set.include_record?(rec) }
    end

    # @return [OAI::Provider::ResumptionToken] The resumption token object with data pulled from
    #   @opts and @response
    def token
      OAI::Provider::ResumptionToken.new(
        @opts.merge(last: @response["nextCursorMark"]),
        nil,
        @response["response"]["numFound"]
      )
    end
  end
end
