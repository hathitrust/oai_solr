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

    # Build a new OAI::Provider::ResumptionToken based on information from the existing
    # token (if any) and return it.
    # @return [OAI::Provider::ResumptionToken] The resumption token object with data pulled from
    #   @opts and @response
    def token
      old_rt_opts = if @opts[:resumption_token]
        OAI::Provider::ResumptionToken.parse(@opts[:resumption_token]).to_conditions_hash
      else
        {prefix: "oai_dc"}
      end
      new_opts = @opts.merge(old_rt_opts, last: @response["nextCursorMark"])
      OAI::Provider::ResumptionToken.new(
        new_opts,
        nil,
        @response["response"]["numFound"]
      )
    end
  end
end
