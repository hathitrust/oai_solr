require "spec_helper"
require "oai_solr/record"
require "oai_solr/marc21_full"
require "json"
require "nokogiri"

RSpec.describe OAISolr::Marc21Full do
  shared_examples_for "full marc record" do |file|
    let(:sdoc) { JSON.parse(File.read("spec/data/#{file}")) }
    let(:oai_record) { OAISolr::Record.new(sdoc) }
    let(:full_marc_xml) { described_class.new.encode(nil, oai_record) }
    let(:full_marc_record) { MARC::XMLReader.new(StringIO.new(full_marc_xml)).first }
    let(:slim_schema) do
      Nokogiri::XML::Schema(File.open(File.dirname(__FILE__) + "/schemas/MARC21slim.xsd"))
    end

    describe "#encode" do
      it "provides valid marc for #{file}" do
        parsed = Nokogiri::XML::Document.parse(full_marc_xml)
        expect(slim_schema.valid?(parsed)).to be true
      end

      it "has 974s for #{file}" do
        orig = oai_record.marc_record
        expect(orig.fields("974").count).to be > 0
        expect(orig.fields("974").count).to eq(full_marc_record.fields("974").count)
      end

      it "has an 008 for #{file}" do
        expect(full_marc_record["008"]).not_to be(nil)
      end

      it "does not have special zephir fields" do
        %w[CID DAT CAT FMT HOL].each do |zephir_field|
          expect(full_marc_record[zephir_field]).to be nil
        end
      end

      it "has a title field" do
        expect(full_marc_record["245"].count).to be > 0
      end

      it "has a subject field" do
        expect(full_marc_record["650"].count).to be > 0
      end

      # true for the two sample records below, not necessarily
      # always these indicators!
      it "has indicators for title field" do
        f = full_marc_record["245"]
        expect(f.indicator1).to eq("1")
        expect(f.indicator2).to eq("0")
      end
    end
  end

  it_behaves_like "full marc record", "000004150.json"
  it_behaves_like "full marc record", "000007599.json"
end
