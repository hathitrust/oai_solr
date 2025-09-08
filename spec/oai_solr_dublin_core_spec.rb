require "json"
require "nokogiri"
require "rights_database"
require "oai_solr/services"

RSpec.describe OAISolr::DublinCore do
  let(:rec) { OAISolr::Record.new(sdoc) }
  let(:dc) { OAISolr::DublinCore.instance.encode(nil, rec) }
  let(:dc_elements) { Nokogiri::XML::Document.parse(dc).children.children }

  describe "#encode" do
    context "with regular record" do
      let(:sdoc) { JSON.parse(File.read("spec/data/001718542.json")) }
      it "does not output empty tags" do
        expect(dc_elements.any? { |e| e.children.empty? }).to be false
      end

      it "returns expected fields" do
        expect(dc_elements.map(&:name)).to include(
          *%w[ title creator subject description
            publisher date type format
            identifier language rights]
        )
      end
    end

    context "with minimal record" do
      let(:sdoc) { JSON.parse(File.read("spec/data/minimal.json")) }
      it "does not output empty tags" do
        expect(dc_elements.any? { |e| e.children.empty? }).to be false
      end

      it "includes minimal fields" do
        expect(dc_elements.map(&:name)).to include(
          *%w[title type identifier rights]
        )
      end
    end
  end

  describe "#rights_statement" do
    let(:sdoc) { JSON.parse(File.read("spec/data/minimal.json")) }
    let(:access_statements) { OAISolr::Services.rights_database.access_statements }

    context "with one statement" do
      it "generates a correct rights statement" do
        statements = [access_statements["pd"]]
        expect(OAISolr::DublinCore.rights_statement(rec, statements)).to match(/.*#pd.*/)
      end
    end

    context "with multiple statements" do
      it "generates a correct compound rights statement" do
        statements = [access_statements["pd"],
          access_statements["cc-by"]]
        expect(OAISolr::DublinCore.rights_statement(rec, statements)).to match(/.*#pd.*#cc-by.*/)
      end
    end
  end
end
