# frozen_string_literal: true

module OAISolr
  # Useful defaults. Note that #earlier and #later are part of the spec for what
  # needs to be in Model, so this is included there
  module Defaults
    # Earliest timestamp from which we'll provide data
    # @return [Time]
    def earliest
      Time.at(0)
    end

    # Latest timestamp for which we'll provide data
    # @return [Time]
    def latest
      Time.now
    end

    # Default parameters for a new ResumptionToken
    # @return [Hash] hash of (symbol-keyed) params
    def default_token_params
      {
        from: earliest,
        until: latest,
        prefix: "oai_dc",
        last: "*"
      }
    end

    # Default parameters for a solr query
    # @return [Hash] hash of (symbol-keyed) solr params
    def default_solr_query_params
      {
        q: "*:*",
        wt: "ruby",
        rows: Settings.page_size,
        sort: "id asc"
      }
    end
  end
end
