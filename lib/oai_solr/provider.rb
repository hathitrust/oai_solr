require "oai"
require "oai_solr/record"

module OAISolr
  class Provider < OAI::Provider::Base
    # TODO this should all come from configuration
    repository_name "Bob's Book Barn"
    repository_url "http://localhost.default.invalid:4567/oai"
    record_prefix "oai:localhost.default.invalid"
    admin_email "admin@default.invalid"
    source_model OAISolr::Record
  end
end
