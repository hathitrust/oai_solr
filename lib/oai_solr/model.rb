require "marc"
require "marc/xmlreader"
require "nokogiri"
require "oai"
require "rsolr"
require "oai_solr/partial_result"
require "oai_solr/record"
require "oai_solr/set"

module OAISolr
  class Model < OAI::Provider::Model
    include OAI::Provider

    def earliest
      Time.at(0)
    end

    def latest
      Time.now
    end

    # @return [Array<OAISolr::Set>] List of sets derived from those listed in the settings file
    def sets
      OAISolr::Sets::VALID_SET_SPECS.map { |spec| OAISolr::Set.for_spec(spec.to_s) }
    end

    def find(selector, opts = {})
      @client = RSolr.connect url: ENV.fetch("SOLR_URL", "http://localhost:9033/solr/catalog")
      if selector == :all
        find_all(opts)
      else
        find_one(selector, opts)
      end
    end

    private

    def find_all(opts)
      (cursor_mark, opts) = restore_options(opts)

      params = {
        q: "*:*",
        wt: "ruby",
        rows: Settings.page_size,
        cursorMark: cursor_mark,
        sort: "id asc"
      }
      set = OAISolr::Set.for_spec(opts[:set])
      params[:fq] = set.filter_query if set.filter_query.any?
      response = @client.get("select", params: params)
      partial_result = OAISolr::PartialResult.new_from_solr_response(response, opts)
      OAI::Provider::PartialResult.new(partial_result.records, partial_result.token)
    end

    # Returns the cursorMark to use for the solr query along with options as
    # parsed from a resumption token
    def restore_options(opts)
      if opts[:resumption_token]
        token = OAI::Provider::ResumptionToken.parse(opts[:resumption_token])
        [token.last_str, token.to_conditions_hash]
      else
        ["*", opts]
      end
    end

    def find_one(selector, opts)
      response = @client.get "select", params: {q: "id:#{selector}", wt: "ruby"}
      OAISolr::Record.new(response["response"]["docs"].first)
    end
  end
end
