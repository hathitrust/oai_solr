# frozen_string_literal: true

require "oai"
require "oai_solr/defaults"

module OAISolr
  class ResumptionToken < OAI::Provider::ResumptionToken
    extend OAISolr::Defaults

    # Given an existing token / string representation of that token,
    # create a new one with the provided options overriding
    # the passed token's values and the new 'last' value set
    def self.from_existing_token(token, **opts)
      old_token = parse(token)
      expiration = opts[:expiration]
      new_opts = old_token.to_conditions_hash.merge(last: old_token.last_str)
      new(new_opts, expiration, old_token.total)
    end

    # Detects and uses a token string if there's one in opts[:resumption_token],
    # otherwise just returns a new token based on the opts
    def self.from_options(opts, expiration: nil, total: nil)
      if opts[:resumption_token]
        from_existing_token(opts[:resumption_token], **opts)
      else
        new(default_token_params.merge(opts), nil, total)
      end
    end
  end
end
