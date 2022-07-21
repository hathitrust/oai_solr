require "oai"
require "oai_solr/model"
require "oai_solr/marc21"
require "oai_solr/dublin_core"

module OAISolr
  class Provider < OAI::Provider::Base
    # TODO this should all come from configuration
    repository_name "Bob's Book Barn"
    repository_url "http://localhost.default.invalid:4567/oai"
    record_prefix "oai:localhost.default.invalid"
    admin_email "admin@default.invalid"
    source_model OAISolr::Model.new
    register_format OAISolr::Marc21.new
    register_format OAISolr::DublinCore.instance
  end
end
