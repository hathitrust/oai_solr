# frozen_string_literal: true

require "oai"
require "oai_solr/defaults"

# Responsible for getting parameters for the current & next page of results
# from a combination of the defaults, given options, and the existing
# resumption token (if any)
module OAISolr
  class Params
    include OAISolr::Defaults
    attr_reader :cursor_mark

    # @param [Hash] params from the incoming OAI request
    def initialize(opts)
      if opts[:resumption_token]
        from_opts(opts)
      else
        @opts = default_token_params.merge(opts)
        @results_so_far = 0
        @cursor_mark = "*"
      end
    end

    def [](key)
      opts[key]
    end

    # @return [OAI::Provider::ResumptionToken] The resumption token to
    # use to get the next page of results, or an empty token if this is
    # the last page.
    def next_token(next_mark:, page_results:, total:, expiration: nil)
      new_results_so_far = results_so_far + page_results

      last = if new_results_so_far < total && next_mark != cursor_mark
        new_results_so_far.to_s + "-" + next_mark
      else
        ""
      end

      OAI::Provider::ResumptionToken.new(opts.merge(last: last), expiration, total)
    end

    private

    def from_opts(opts)
      @old_token = OAI::Provider::ResumptionToken.parse(opts[:resumption_token])
      (results_so_far_str, @cursor_mark) = old_token.last_str.split("-", 2)
      @results_so_far = results_so_far_str.to_i
      @opts = old_token.to_conditions_hash.merge(opts)
    end

    attr_reader :old_token, :results_so_far, :opts
  end
end
