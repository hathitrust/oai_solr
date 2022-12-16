require "spec_helper"
require "oai_solr/result_set"
require "oai_solr/params"

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

  def model(last: nil)
    opts = {}

    if last
      opts = {resumption_token: token_prefix + last}
    end

    described_class.new_from_solr_response(response, OAISolr::Params.new(opts))
  end

  let(:page_size) { OAISolr::Settings.page_size }
  let(:sdoc) { JSON.parse(File.read("spec/data/001718542.json")) }
  let(:response) { make_response(doc_count: 1) }
  let(:token_prefix) { ".f(1970-01-01T00:00:00Z).u(2022-01-01T00:00:00Z):" }

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

    # token format: results_so_far-total_results-solr_cursor_mark

    context "with last page of results != page size" do
      # simulated second page of results; 11 total; 10 already served
      let(:response) { make_response(doc_count: 1, num_found: 11) }

      it "returns empty resumption token" do
        expect(model(last: "10-11-old_token").token.to_s).to eq("")
      end
    end

    context "with last page of results = page size" do
      # simulated last page of results
      let(:response) { make_response(doc_count: 10, num_found: 30) }
      it "returns empty resumption token" do
        expect(model(last: "20-30-old_token").token.to_s).to eq("")
      end
    end

    context "with in-between page of results" do
      # simulated second page - 10 so far, 10 on this page, 10 more to go
      let(:response) { make_response(doc_count: 10, num_found: 30) }
      it "returns resumption token" do
        expect(model(last: "10-30-old_token").token.to_s).to match(/:20-30-next_mark/)
      end
    end

    context "when numResults changes from page to page" do
      # simulated results with 31 total results
      let(:response) { make_response(doc_count: 10, num_found: 31) }
      it "raises OAI::ResumptionTokenException" do
        expect { model(last: "10-30-old_token").token }.to raise_exception(OAI::ResumptionTokenException)
      end
    end
  end
end
