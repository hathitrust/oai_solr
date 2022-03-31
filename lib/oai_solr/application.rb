require "sinatra/base"
require "sinatra/reloader"
require "oai_solr/provider"

module OAISolr
  class Application < Sinatra::Application
    configure :development do
      register Sinatra::Reloader
    end

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
  end
end
