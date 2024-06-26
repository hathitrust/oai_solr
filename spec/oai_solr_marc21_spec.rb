require "spec_helper"
require "oai_solr/record"
require "oai_solr/marc21"
require "json"
require "nokogiri"

RSpec.describe OAISolr::Marc21 do
  shared_examples_for "slim marc record" do |file|
    let(:sdoc) { JSON.parse(File.read("spec/data/#{file}")) }
    let(:rec) { OAISolr::Record.new(sdoc) }
    let(:marc21) { described_class.new }
    let(:slim_schema) do
      Nokogiri::XML::Schema(File.open(File.dirname(__FILE__) + "/schemas/MARC21slim.xsd"))
    end

    describe "#slim_marc" do
      it "provides valid marc for #{file}" do
        slimmed = marc21.slim_marc(rec.marc_record)
        parsed = Nokogiri::XML::Document.parse(slimmed.to_xml.to_s)
        expect(slim_schema.valid?(parsed)).to be true
      end

      it "replaces the 974s with 856s for #{file}" do
        orig = rec.marc_record
        expect(orig.fields("974").count).to be > 0
        slim = marc21.slim_marc(rec.marc_record)
        expect(orig.fields("974").count).to eq(slim.fields("856").count)
      end

      it "removes the 008 for #{file}" do
        expect(marc21.slim_marc(rec.marc_record)["008"]).to be_nil
      end

      it "has an author field" do
        expect(marc21.slim_marc(rec.marc_record)["100"].count).to be > 0
      end

      it "has a title field" do
        expect(marc21.slim_marc(rec.marc_record)["245"].count).to be > 0
      end

      it "has a subject field" do
        expect(marc21.slim_marc(rec.marc_record)["650"].count).to be > 0
      end

      # true for the two sample records below, not necessarily
      # always these indicators!
      it "has indicators for title field" do
        f = marc21.slim_marc(rec.marc_record)["245"]
        expect(f.indicator1).to eq("1")
        expect(f.indicator2).to eq("0")
      end
    end
  end

  it_behaves_like "slim marc record", "000004150.json"
  it_behaves_like "slim marc record", "000007599.json"
end
