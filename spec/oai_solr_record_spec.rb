require "rspec"
require "oai_solr/record"
require "pp"

RSpec.describe OAISolr::Record do
  let(:sdoc) { JSON.parse(File.read("spec/data/solr_document.json")) }
  let(:rec) { described_class.new(sdoc) }
  let(:oai_dc_schema) do
    Nokogiri::XML::Schema(File.open(File.dirname(__FILE__) + "/schemas/oai_dc.xsd"))
  end

  describe "#to_oai_dc" do
    xit "provides valid dublin core" do
      parsed = Nokogiri::XML::Document.parse(rec.to_oai_dc)
      expect(oai_dc_schema.valid?(parsed)).to be true
    end

    xit "has dc:title" do
      parsed = Nokogiri::XML::Document.parse(rec.to_oai_dc)
      expect(parsed.xpath("title")).to eq("a title")
    end
    it "has dc:creator"
    it "has dc:type text"
    it "has dc:publisher"
    it "has dc:date"
    it "has dc:language"
    it "has dc:format"
    it "has dc:description"
    it "has dc:identifier"
    it "has dc:rights"
  end
end
