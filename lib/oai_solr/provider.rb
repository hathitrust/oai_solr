require "oai"
require "oai_solr/model"
require "oai_solr/marc21"
require "oai_solr/dublin_core"

module OAISolr
  class Provider < OAI::Provider::Base
    repository_name Settings.repository_name
    repository_url Settings.repository_url
    record_prefix Settings.record_prefix
    admin_email Settings.admin_email
    source_model OAISolr::Model.new
    register_format OAISolr::Marc21.new
    register_format OAISolr::DublinCore.instance
  end
end
