# frozen_string_literal: true

module OAISolr
  module Defaults
    def earliest
      Time.at(0)
    end

    def latest
      Time.now
    end

    def default_token_params
      {
        from: earliest,
        until: latest,
        prefix: "oai_dc",
        last: "*"
      }
    end

    def default_query_params
      {
        q: "*:*",
        wt: "ruby",
        rows: Settings.page_size,
        sort: "id asc"
      }
    end
  end
end
