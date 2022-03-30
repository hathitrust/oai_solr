require "rspec"
require "rack/test"

require_relative "../oai_solr"

RSpec.describe "oai_solr" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "identify" do
    it "can identify" do
      get "/oai", verb: "Identify"
      expect(last_response).to be_ok
    end
  end
end
