require "rspec"
require "oai_solr/model"

RSpec.describe OAISolr::Model do
  describe "#earliest" do
    it "returns the earliest last modified record date"
  end

  describe "#latest" do
    it "returns the latest modified record date"
  end

  describe "#sets" do
    it "returns the configured sets"
  end

  describe "#find" do
    it "can find a single record"
    it "can find all records"
    it "can find records modified since a given date"
    it "can find records modified before a given date"
  end

  describe "#page_size" do
    it "has a default PAGE SIZE" do
      expect(described_class.new.page_size).to eq(10)
    end
  end

  describe "resumption tokens"
end
