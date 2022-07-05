require "oai"
require "rsolr"
require "oai_solr/record"

module OAISolr
  class Model < OAI::Provider::Model
    include OAI::Provider

    # TODO should come from configuration. Using small page size for now to
    # speed up tests
    PAGE_SIZE = 10

    def earliest
      Time.at(0)
    end

    def latest
      Time.now
    end

    def sets
      nil
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

      response = @client.get("select", params: {
        q: "*:*",
        wt: "ruby",
        rows: PAGE_SIZE,
        cursorMark: cursor_mark,
        sort: "id asc"
      })

      OAI::Provider::PartialResult.new(
        response["response"]["docs"].map { |doc| OAISolr::Record.new(doc) },
        resumption_token(opts, response)
      )
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

    def resumption_token(opts, response)
      OAI::Provider::ResumptionToken.new(
        opts.merge(last: response["nextCursorMark"]),
        nil,
        response["response"]["numFound"]
      )
    end
  end
end
