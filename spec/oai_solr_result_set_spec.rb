require "spec_helper"
require "oai_solr/result_set"

RSpec.describe OAISolr::ResultSet do
  def make_response(doc_count:, num_found: doc_count, cursor_mark: "mark", next_mark: "next_mark")
    {
      "responseHeader" => {
        "cursorMark" => cursor_mark
      },
      "response" => {
        "docs" => [sdoc] * doc_count,
        "numFound" => num_found
      },
      "nextCursorMark" => next_mark
    }
  end

  let(:page_size) { OAISolr::Settings.page_size }
  let(:sdoc) { JSON.parse(File.read("spec/data/001718542.json")) }
  let(:response) { make_response(doc_count: 1) }
  let(:model) { described_class.new_from_solr_response(response, {}) }

  describe "#records" do
    it "returns an array of OAISolr::Record" do
      expect(model.records).to be_instance_of(Array)
      expect(model.records[0]).to be_kind_of(OAISolr::Record)
    end
  end

  describe "#token" do
    context "with more results than page size" do
      let(:response) { make_response(doc_count: page_size, num_found: page_size + 1) }

      it "returns an OAI::Provider::ResumptionToken" do
        expect(model.token).to be_kind_of(OAI::Provider::ResumptionToken)
        expect(model.token.to_s).not_to eq("")
      end
    end

    context "with fewer results than page size" do
      let(:response) { make_response(doc_count: 1) }

      it "returns nil" do
        expect(model.token).to be_nil
      end
    end

    context "with numFound > doc count" do
      # simulated second page of results
      let(:response) { make_response(doc_count: 1, num_found: 11) }

      it "returns empty resumption token" do
        expect(model.token.to_s).to eq("")
      end
    end

    context "with last page of results = page size" do
    end
  end
end
