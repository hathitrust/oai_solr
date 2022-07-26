require "json"
require "oai_solr/record"
require "nokogiri"

RSpec.describe OAISolr::Record do
  let(:sdoc) { JSON.parse(File.read("spec/data/000007599.json")) }
  let(:rec) { described_class.new(sdoc) }
  let(:parsed) { Nokogiri::XML::Document.parse(rec.to_oai_dc) }
  let(:oai_dc_schema) do
    Nokogiri::XML::Schema(File.open(File.dirname(__FILE__) + "/schemas/oai_dc.xsd"))
  end

  describe "#to_oai_dc" do
    xit "provides valid dublin core" do
      parsed = Nokogiri::XML::Document.parse(rec.to_oai_dc)
      expect(oai_dc_schema.valid?(parsed)).to be true
    end

    it "has dc:title" do
      expect(parsed.css("dc|title").text).to eq("Wildlife management")
    end

    it "has dc:creator" do
      expect(parsed.css("dc|creator").map { |c| c.text }).to include("Trippensee, Reuben Edwin,")
    end

    it "has dc:type text"
    it "has dc:publisher"
    it "has dc:date"
    it "has dc:language"
    it "has dc:format"
    it "has dc:description"
    it "has OCN as an dc:identifier" do
      expect(parsed.css("dc|identifier").map { |c| c.text }).to include("(OCoLC)562083")
    end
    it "has item handle as an dc:identifier" do
      handle = "http://hdl.handle.net/2027/uc1.31822013347232"
      expect(parsed.css("dc|identifier").map { |c| c.text }).to include(handle)
    end

    it "has dc:rights"
  end
end
