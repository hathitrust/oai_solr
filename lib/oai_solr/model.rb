require "marc"
require "marc/xmlreader"
require "nokogiri"
require "oai"
require "rsolr"
require "oai_solr/result_set"
require "oai_solr/record"
require "oai_solr/set"
require "oai_solr/defaults"

# Queries Solr for results matching the given criteria
module OAISolr
  class Model < OAI::Provider::Model
    include OAI::Provider
    include OAISolr::Defaults

    # @return [Array<OAISolr::Set>] List of sets derived from those listed in the settings file
    def sets
      OAISolr::Set::VALID_SET_SPECS.map { |spec| OAISolr::Set.for_spec(spec.to_s) }
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
      oai_params = OAISolr::Params.new(opts)
      response = @client.get("select", params: solr_params(oai_params))
      result = OAISolr::ResultSet.new_from_solr_response(response, oai_params)

      if result.is_partial?
        OAI::Provider::PartialResult.new(result.records, result.token)
      else
        result.records
      end
    end

    def find_one(selector, opts)
      response = @client.get "select", params: {q: "id:#{selector}", wt: "ruby"}
      OAISolr::Record.new(response["response"]["docs"].first)
    end

    # Build a hash of params to be request from Solr
    # @param [OAISolr::Params] options parsed from incoming request
    def solr_params(oai_params)
      solr_params = default_solr_query_params.merge(cursorMark: oai_params.cursor_mark)
      solr_params[:fq] = filter_query(oai_params)
      solr_params
    end

    def filter_query(opts)
      daterange_fq(opts) + set_fq(opts)
    end

    # Get us a parameter string for "from" and "until" options
    # @param [OAISolr::Params] options
    def daterange_fq(opts)
      if opts[:from] && opts[:until]
        ["ht_id_update:[#{opts[:from].strftime("%Y%m%d")} TO #{opts[:until].strftime("%Y%m%d")}] OR (deleted:true AND time_of_index:[#{opts[:from].strftime("%FT%TZ")} TO #{opts[:until].strftime("%FT%TZ")}])"]
      else
        []
      end
    end

    def set_fq(opts)
      OAISolr::Set.for_spec(opts[:set]).filter_query
    end
  end
end
