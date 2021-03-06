$LOAD_PATH << "./lib"

require "sinatra"
require "sinatra/reloader"
require "oai_solr/provider"

def handle_oai
  content_type "text/xml"
  OAISolr::Provider.new.process_request(params.to_h)
end

post "/oai" do
  handle_oai
end

get "/oai" do
  handle_oai
end
