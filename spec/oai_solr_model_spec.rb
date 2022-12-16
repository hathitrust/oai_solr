require "spec_helper"
require "oai_solr/model"

RSpec.describe OAISolr::Model do
  let(:model) { described_class.new }

  describe "#earliest" do
    it "returns the earliest last modified record date available" do
      expect(described_class.new.earliest).to (be > Time.at(0)) & (be < Time.now)
    end
  end

  describe "#latest" do
    it "returns the latest modified record date available" do
      # We will just use right now because the point is a null limit
      now = Time.now
      expect(described_class.new.latest).to be > now
    end
  end

  describe "#sets" do
    it "returns the configured sets" do
      expect(model.sets).to be_instance_of(Array)
      expect(model.sets.count).to be > 0
      expect(model.sets).to all(be_kind_of(OAISolr::Set))
    end
  end

  describe "#find" do
    it "can find a single record" do
      id = existing_record["id"]
      expect(model.find(id, {}).solr_value("id")).to eq(id)
    end

    it "can find all records" do
      partial_result = described_class.new.find(:all)
      expect(partial_result.records.length).to eq(OAISolr::Settings.page_size)
      expect(partial_result.token.total).to eq(total_docs)
    end

    # dates based on sample records
    it "can find records modified since a given date" do
      expect(described_class.new.find(:all, {from: Date.parse("2022-05-01"), until: Date.today}).records.map { |r| r.solr_document["ht_id_update"] }).to all(include(be >= 20220501))
    end

    it "can find records modified before a given date" do
      expect(described_class.new.find(:all, {from: Time.at(0).to_date, until: Date.parse("2021-09-25")}).records.map { |r| r.solr_document["ht_id_update"] }).to all(include(be <= 20210925))
    end

    it "interprets from as >= and to as <=" do
      expect(described_class.new.find(:all, {from: Date.parse("2021-09-25"), until: Date.parse("2021-09-25")}).records.map { |r| r.solr_document["ht_id_update"] }).to all(include(eq 20210925))
    end

    it "raises OAI::ResumptionTokenException when given a bad resumption token" do
      expect { described_class.new.find(:all, {resumption_token: "nonsense"}) }.to raise_error(OAI::ResumptionTokenException)
    end

    it "raises OAI::ResumptionTokenException when given a bad 'last' part of resumption token" do
      expect { described_class.new.find(:all, {resumption_token: "marc21.f(2013-08-01T00:00:00Z).u(#{Date.today}T00:00:00Z):nonsense"}) }.to raise_error(OAI::ResumptionTokenException)
    end
  end
end
