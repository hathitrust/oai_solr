require "rspec"
require "oai_solr/partial_result"

RSpec.describe OAISolr::PartialResult do
  let(:sdoc) { JSON.parse(File.read("spec/data/001718542.json")) }
  let(:response) { {"response" => {"docs" => [sdoc], "numFound" => 1}} }
  let(:model) { described_class.new_from_solr_response(response, {}) }

  describe "#records" do
    it "returns an array of OAISolr::Record" do
      expect(model.records).to be_instance_of(Array)
      expect(model.records[0]).to be_kind_of(OAISolr::Record)
    end
  end

  describe "#token" do
    it "returns an OAI::Provider::ResumptionToken" do
      expect(model.token).to be_kind_of(OAI::Provider::ResumptionToken)
    end
  end
end
