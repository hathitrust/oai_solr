require "rspec"
require "rack/test"
require "nokogiri"

require "oai_solr/application"

RSpec.describe "OAISolr" do
  include Rack::Test::Methods

  let(:oai_endpoint) { "/oai" }

  def app
    OAISolr::Application
  end

  shared_examples "valid oai response" do
    let(:oai_schema) do
      Nokogiri::XML::Schema(File.read(File.dirname(__FILE__) + "/OAI-PMH.xsd"))
    end

    it "returns ok" do
      expect(last_response).to be_ok
    end

    it "returns xml" do
      expect(last_response.content_type).to eq("text/xml;charset=utf-8")
    end

    xit "returns valid xml according to the OAI schema" do
      doc = Nokogiri::XML::Document.parse(last_response.body)
      expect(oai_schema.valid?(doc)).to be true
    end
  end

  describe "Identify" do
    before(:each) { get oai_endpoint, verb: "Identify" }
    it_behaves_like "valid oai response"
  end

  describe "ListMetadataFormats" do
    before(:each) { get oai_endpoint, verb: "ListMetadataFormats" }
    it_behaves_like "valid oai response"
  end

  xdescribe "ListSets" do
    before(:each) { get oai_endpoint, verb: "ListSets" }
    it_behaves_like "valid oai response"
  end

  xdescribe "ListIdentifiers" do
    before(:each) { get oai_endpoint, verb: "ListIdentifiers" }
    it_behaves_like "valid oai response"
  end

  xdescribe "ListRecords" do
    before(:each) { get oai_endpoint, verb: "ListRecords" }
    it_behaves_like "valid oai response"
  end

  xdescribe "GetRecord" do
    # additional required params ?
    before(:each) { get oai_endpoint, verb: "GetRecord" }
    it_behaves_like "valid oai response"
  end
end
