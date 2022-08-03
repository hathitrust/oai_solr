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

    def sets
      Settings.sets.map { |spec| OAISolr::Set.for_spec(spec.to_s) }
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
      response = @client.get("select", params: params(opts))

      partial_result = OAISolr::PartialResult.new_from_solr_response(response, opts)
      OAI::Provider::PartialResult.new(partial_result.records, partial_result.token)
      # OAI::Provider::PartialResult.new(
      #   response["response"]["docs"].map { |doc| OAISolr::Record.new(doc) },
      #   resumption_token(opts, response)
      # )
    end

    def find_one(selector, opts)
      response = @client.get "select", params: {q: "id:#{selector}", wt: "ruby"}
      OAISolr::Record.new(response["response"]["docs"].first)
    end

    # TODO factor this all out somewhere else - SolrParams?

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

    # Build a hash of params to be request from Solr
    # @param [Hash] options list including cursor_mark
    def params(opts)
      (cursor_mark, opts) = restore_options(opts)
      params = {
        q: "*:*",
        wt: "ruby",
        rows: Settings.page_size,
        cursorMark: cursor_mark,
        sort: "id asc"
      }
      params[:fq] = filter_query(opts) if filter_query(opts)
      params
    end

    def filter_query(opts)
      fq = [daterange_fq(opts), set_fq(opts)]
      fq.join(" ") if fq.any?
    end

    # Get us a parameter string for "from" and "until" options
    # @param [Hash] options
    def daterange_fq(opts)
      if opts[:from] && opts[:until]
        "ht_id_update:[#{opts[:from].strftime("%Y%m%d")} TO #{opts[:until].strftime("%Y%m%d")}]"
      end
    end

    def set_fq(opts)
      OAISolr::Set.for_spec(opts[:set]).filter_query
    end
  end
end
