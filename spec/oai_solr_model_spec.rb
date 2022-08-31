require "rspec"
require "oai_solr/model"

RSpec.describe OAISolr::Model do
  let(:model) { described_class.new }

  describe "#earliest" do
    it "returns the earliest last modified record date"
  end

  describe "#latest" do
    it "returns the latest modified record date"
  end

  describe "#sets" do
    it "returns the configured sets" do
      expect(model.sets).to be_instance_of(Array)
      expect(model.sets.count).to be > 0
      expect(model.sets).to all(be_kind_of(OAISolr::Set))
    end
  end

  describe "#find" do
    it "can find a single record"
    it "can find all records"
    it "can find records modified since a given date"
    it "can find records modified before a given date"
  end

  describe "resumption tokens"
end
