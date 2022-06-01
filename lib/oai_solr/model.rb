require "oai"
require "rsolr"
require "oai_solr/record"

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
      nil
    end

    def find(selector, opts = {})
      @client = RSolr.connect url: ENV.fetch("SOLR_URL", "http://localhost:9033/solr/catalog")
      if selector == :all
        raise "all not implemented"
        # response = @client.get "select", :params => {:q => "*:*", :wt => "ruby"}
      else
        response = @client.get "select", params: {q: "id:#{selector}", wt: "ruby"}
        record = OAISolr::Record.new(response["response"]["docs"].first)
      end
      record
    end
  end
end
