# frozen_string_literal: true

require "oai_solr/record"
require "oai_solr/set"
require "oai_solr/resumption_token"
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

    # Build a new OAISolr::ResumptionToken based on information from the existing
    # token (if any) and return it.
    # @return [OAISolr::ResumptionToken] The resumption token object with data pulled from
    #   @opts and @response
    def token
      total = @response["response"]["numFound"]
      opts = @opts.merge(last: @response["nextCursorMark"])
      OAISolr::ResumptionToken.from_options(opts, total: total)
    end
  end
end
