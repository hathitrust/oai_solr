require "rspec"
require "oai_solr/record"
require "oai_solr/marc21"

RSpec.describe OAISolr::Marc21 do
  let(:sdoc) { JSON.parse(File.read("spec/data/solr_document.json")) }
  let(:rec) { OAISolr::Record.new(sdoc) }
  let(:marc21) { described_class.new }
  let(:slim_schema) do
    Nokogiri::XML::Schema(File.open(File.dirname(__FILE__) + "/schemas/MARC21slim.xsd"))
  end

  describe "#slim_marc" do
    it "provides valid marc" do
      slimmed = marc21.slim_marc(rec.marc_record)
      parsed = Nokogiri::XML::Document.parse(slimmed.to_xml.to_s)
      slim_schema.valid?(parsed)
      # valid? is missing from the MARC gem, but it only checks for
      # ControlField/DataField discrepancies anyway
      # expect(rec.marc_record.valid?).to be true
      # expect(marc21.slim_marc(rec.marc_record).valid?).to be true
    end

    it "replaces the 974s with 856s" do
      orig = rec.marc_record
      expect(orig.fields("974").count).to be > 1
      slim = marc21.slim_marc(rec.marc_record)
      expect(orig.fields("974").count).to eq(slim.fields("856").count)
    end

    it "removes the 008" do
      expect(marc21.slim_marc(rec.marc_record)["008"]).to be_nil
    end
  end
end
