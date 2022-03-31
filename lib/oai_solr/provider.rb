require "oai"
require "oai_solr/record"

module OAISolr
  class Provider < OAI::Provider::Base
    repository_name "Bob's Book Barn"
    repository_url "http://localhost:4567/oai"
    record_prefix "oai:localhost"
    admin_email "admin@default.invalid"
    source_model OAISolr::Record
  end
end
