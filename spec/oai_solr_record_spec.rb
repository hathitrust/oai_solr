require "spec_helper"
require "json"
require "oai_solr/record"
require "nokogiri"

RSpec.describe OAISolr::Record do
  context "with a deleted record" do
    let(:sdoc) { JSON.parse(File.read("spec/data/deleted_item.json")) }
    let(:rec) { described_class.new(sdoc) }

    it "knows it is deleted" do
      expect(rec).to be_deleted
    end

    it "can get updated_at" do
      expect(rec.updated_at).to respond_to(:utc)
    end
  end

  context "with a record with no 300 field" do
    let(:sdoc) { JSON.parse(File.read("spec/data/000004150.json")) }
    let(:rec) { described_class.new(sdoc) }

    it "can get oai_dc" do
      expect(rec.to_oai_dc).not_to be nil
    end
  end

  describe "#to_oai_dc" do
    let(:sdoc) { JSON.parse(File.read("spec/data/000007599.json")) }
    let(:rec) { described_class.new(sdoc) }
    let(:parsed) { Nokogiri::XML::Document.parse(rec.to_oai_dc) }

    it "has dc:title" do
      expect(parsed.css("dc|title").text).to eq("Wildlife management")
    end

    it "has dc:creator" do
      expect(parsed.css("dc|creator").map { |c| c.text }).to include("Trippensee, Reuben Edwin,")
    end

    it "has dc:type text" do
      expect(parsed.css("dc|type").text).to eq("text")
    end

    it "has dc:publisher" do
      expect(parsed.css("dc|publisher").text).to eq("McGraw-Hill,")
    end

    it "has dc:date" do
      expect(parsed.css("dc|date").text).to eq("1948")
    end

    it "has dc:language" do
      expect(parsed.css("dc|language").text).to eq("English")
    end

    it "has dc:format" do
      expect(parsed.css("dc|format").text).to eq("Book")
    end

    it "has dc:description" do
      expect(parsed.css("dc|description").text).to eq("2 v. illus., maps 24 cm")
    end

    it "has OCN as a dc:identifier" do
      expect(parsed.css("dc|identifier").map { |c| c.text }).to include("(OCoLC)562083")
    end

    it "has ISBN as a dc:identifier" do
      expect(parsed.css("dc|identifier").map { |c| c.text }).to include("0080117325")
    end

    it "has item handle as an dc:identifier" do
      handle = "http://hdl.handle.net/2027/uc1.31822013347232"
      expect(parsed.css("dc|identifier").map { |c| c.text }).to include(handle)
    end

    it "has dc:rights" do
      expect(parsed.css("dc|rights").text).to match(/^Items in this record/)
    end
  end
end
