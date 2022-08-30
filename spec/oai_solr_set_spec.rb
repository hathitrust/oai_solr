require "rspec"
require "oai_solr/set"

RSpec.describe OAISolr::Set do
  let(:rec) { described_class.new(spec: "hathitrust:pd") }

  describe "#spec" do
    it "returns the spec it was initialized with" do
      expect(rec.spec).to eq("hathitrust:pd")
    end
  end

  describe "#name" do
    it "returns a name" do
      expect(rec.name).to be_instance_of(String)
    end
  end

  describe "#fq" do
    it "returns a feature query array" do
      expect(rec.fq).to be_instance_of(Array)
    end
  end

  describe "#new" do
    it "raises on unknown spec" do
      expect { described_class.new(spec: "hathitrust:invalid") }.to raise_error(StandardError)
    end
  end
end
