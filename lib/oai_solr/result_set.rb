# frozen_string_literal: true

require "oai_solr/record"
require "oai_solr/set"
require "oai_solr/params"
require "nokogiri"

# Handles results from Solr and transforms them into output records for
# OAI.
module OAISolr
  class ResultSet
    attr_reader :params

    def self.new_from_solr_response(response, oai_params)
      new(solr_response: response, oai_params: oai_params)
    end

    # @param [Hash] solr_response Full response from the solr query (parsed from the JSON)
    # @option opts [OAISolr::Params] options parsed from this request
    def initialize(solr_response:, oai_params:)
      @response = solr_response
      @params = oai_params
      @set = OAISolr::Set.for_spec(params[:set])
    end

    # @return [Array<OAISolr::Record>] Records from the response that fit the set criteria,
    #   possibly munged to remove some fields
    def records
      @response["response"]["docs"]
        .map { |doc| OAISolr::Record.new(doc) }
        .map { |rec| @set.remove_unwanted_974s(rec) }
        .select { |rec| @set.include_record?(rec) }
    end

    def total
      @response["response"]["numFound"]
    end

    def is_partial?
      total > Settings.page_size
    end

    # Build a new OAI::Provider::ResumptionToken based on information from the existing
    # token (if any) and return it.
    #
    # @return [OAI::Provider::ResumptionToken] The resumption token object with data
    # pulled from @params and @response
    def token
      return unless is_partial?

      params.next_token(total: total,
        next_mark: @response["nextCursorMark"],
        page_results: @response["response"]["docs"].count)
    end
  end
end
