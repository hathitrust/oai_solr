$LOAD_PATH << "./lib"

require "sinatra"
require "sinatra/reloader"
require "oai_solr/settings"
require "oai_solr/provider"

def handle_oai
  content_type "text/xml"
  OAISolr::Provider.new.process_request(params.to_h)
end

post "/" do
  handle_oai
end

get "/" do
  handle_oai
end
