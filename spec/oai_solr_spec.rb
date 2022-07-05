require "rspec"
require "rack/test"
require "nokogiri"

require_relative "../oai_solr"

RSpec.describe "OAISolr" do
  include Rack::Test::Methods

  let(:oai_endpoint) { "/oai" }

  def app
    Sinatra::Application
  end

  def existing_record_id
    # Independently query solr for a record id that actually exists
    @client = RSolr.connect url: ENV.fetch("SOLR_URL", "http://localhost:9033/solr/catalog")
    @client.get("select", params: {q: "*:*", wt: "ruby", rows: 1})["response"]["docs"][0]["id"]
  end

  shared_examples "valid oai response" do
    let(:oai_schema) do
      Nokogiri::XML::Schema(File.open(File.dirname(__FILE__) + "/schemas/oai-schemas.xsd"))
    end

    it "returns ok" do
      expect(last_response).to be_ok
    end

    it "returns xml" do
      expect(last_response.content_type).to eq("text/xml;charset=utf-8")
    end

    it "returns valid xml according to the OAI schema" do
      Dir.mktmpdir do |tmpdir|
        File.write("#{tmpdir}/last_response.xml", last_response.body)
        expect(system("StdInParse -f -n -s -v=always < #{tmpdir}/last_response.xml")).to be true
        # doc = Nokogiri::XML::Document.parse(last_response.body)
        # expect(oai_schema.valid?(doc)).to be true
      end
    end
  end

  describe "Identify" do
    before(:each) { get oai_endpoint, verb: "Identify" }
    it_behaves_like "valid oai response"
  end

  describe "ListMetadataFormats" do
    before(:each) { get oai_endpoint, verb: "ListMetadataFormats" }
    it_behaves_like "valid oai response"

    it "claims to support dublin core" do
      doc = Nokogiri::XML::Document.parse(last_response.body)
      expect(doc.xpath("//xmlns:metadataPrefix").map { |mp| mp.content }).to include("oai_dc")
    end

    it "claims to support marc21" do
      doc = Nokogiri::XML::Document.parse(last_response.body)
      expect(doc.xpath("//xmlns:metadataPrefix").map { |mp| mp.content }).to include("marc21")
    end
  end

  describe "ListSets" do
    before(:each) { get oai_endpoint, verb: "ListSets" }
    it_behaves_like "valid oai response"
    it "includes hathitrust:pd"
    it "includes hathitrust:pdus"
    it "includes hathitrust:ump"
  end

  describe "ListIdentifiers" do
    before(:each) { get oai_endpoint, verb: "ListIdentifiers" }
    it_behaves_like "valid oai response"
    it "provides a page of N results"
    it "provides resumption token"
    it "can fetch additional pages of N results"
  end

  describe "ListRecords" do
    before(:each) { get oai_endpoint, verb: "ListRecords", metadataPrefix: "oai_dc" }
    it_behaves_like "valid oai response"
    it "provides a page of N results"
    it "provides resumption token"
    it "can fetch additional pages of N results"
  end

  describe "GetRecord DublinCore" do
    # TODO: use record identifier known to be in sample solr
    before(:each) { get oai_endpoint, verb: "GetRecord", metadataPrefix: "oai_dc", identifier: existing_record_id } 
    it_behaves_like "valid oai response"

    it "can get a record as dublin core"
  end

  describe "GetRecord MARC" do
    before(:each) { get oai_endpoint, verb: "GetRecord", metadataPrefix: "marc21", identifier: existing_record_id }
    it_behaves_like "valid oai response"

    it "can get a record as MARC" do
      doc = MARC::XMLReader.new(StringIO.new(last_response.body)).first
      expect(doc.leader).to match(/[\dA-Za-z ]{23}/)
    end
  end

  it "can handle post requests" do
    post oai_endpoint, verb: "GetRecord", metadataPrefix: "oai_dc", identifier: "nonexistent"
  end
end
