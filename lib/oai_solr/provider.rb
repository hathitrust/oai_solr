require "oai"
require "oai_solr/settings"
require "oai_solr/model"
require "oai_solr/marc21"
# Not currently enabled
#  require "oai_solr/marc21_full"
require "oai_solr/dublin_core"

module OAISolr
  class Provider < OAI::Provider::Base
    repository_name Settings.repository_name
    repository_url Settings.repository_url
    record_prefix Settings.record_prefix
    admin_email Settings.admin_email
    source_model OAISolr::Model.new
    register_format OAISolr::Marc21.new
    # Not currently enabled
    # register_format OAISolr::Marc21Full.new
    register_format OAISolr::DublinCore.instance
    sample_id Settings.sample_identifier
    update_granularity OAI::Const::Granularity::LOW
    extra_description File.read("config/extra_description.xml")
  end
end
