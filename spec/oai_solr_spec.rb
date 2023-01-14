require "spec_helper"
require "rack/test"
require "nokogiri"
require "set"

RSpec.describe "OAISolr" do
  include Rack::Test::Methods

  let(:oai_endpoint) { "/" }
  # number of items in sample solr
  let(:min_htid_update) { Date.parse(existing_record["ht_id_update"].min.to_s) }
  let(:max_htid_update) { Date.parse(existing_record["ht_id_update"].max.to_s) }
  before(:all) { add_deleted_documents }
  let(:ns_map) { {"marc" => "http://www.loc.gov/MARC21/slim"} }

  def deleted_document_date
    solr_client.get("select", params: solr_params.merge(q: "deleted:true"))["response"]["docs"][0]["time_of_index"]
  end

  def add_deleted_documents
    # Make sure we have at least N deleted documents in the index
    s = solr_client
    want_deleted_count = 5
    deleted_count = s.get("select", params: solr_params.merge(q: "deleted:true"))["response"]["numFound"]
    min_id = s.get("select", params: solr_params.merge(sort: "id asc"))["response"]["docs"][0]["id_int"]

    (want_deleted_count - deleted_count).times do
      s.add({
        "id" => sprintf("%09d", (min_id -= 1)),
        "deleted" => true,
        "time_of_index" => Date.parse("2022-12-01").to_time
      })
    end

    s.commit
  end

  def app
    Sinatra::Application
  end

  def doc
    Nokogiri::XML::Document.parse(last_response.body)
  end

  shared_examples "valid oai response" do
    it "returns ok" do
      expect(last_response).to be_ok
    end

    it "returns xml" do
      expect(last_response.content_type).to eq("text/xml;charset=utf-8")
    end

    it "returns valid xml according to the OAI schema" do
      Dir.mktmpdir do |tmpdir|
        File.write("#{tmpdir}/last_response.xml", last_response.body)
        expect(system("validateCache #{__dir__}/../config/schema.cache #{tmpdir}/last_response.xml > /dev/null")).to be true
      end
    end
  end

  describe "Identify" do
    before(:each) { get oai_endpoint, verb: "Identify" }
    it_behaves_like "valid oai response"
  end

  describe "ListMetadataFormats" do
    before(:each) { get oai_endpoint, verb: "ListMetadataFormats" }
    it_behaves_like "valid oai response"

    it "claims to support dublin core" do
      expect(doc.xpath("//xmlns:metadataPrefix").map { |mp| mp.content }).to include("oai_dc")
    end

    it "claims to support marc21" do
      expect(doc.xpath("//xmlns:metadataPrefix").map { |mp| mp.content }).to include("marc21")
    end
  end

  describe "ListSets" do
    before(:each) { get oai_endpoint, verb: "ListSets" }
    it_behaves_like "valid oai response"

    it "includes hathitrust:pd" do
      expect(doc.xpath("//xmlns:setSpec").map { |mp| mp.content }).to include("hathitrust:pd")
    end

    it "includes hathitrust:pdus" do
      expect(doc.xpath("//xmlns:setSpec").map { |mp| mp.content }).to include("hathitrust:pdus")
    end

    xit "includes hathitrust:ump"
  end

  describe "ListIdentifiers" do
    before(:each) { get oai_endpoint, verb: "ListIdentifiers" }
    it_behaves_like "valid oai response"
    # it_behaves_like "paged oai response"
  end

  describe "ListRecords" do
    before(:each) { get oai_endpoint, verb: "ListRecords", metadataPrefix: "oai_dc" }

    it "provides a page of N results" do
      expect(doc.xpath("count(//xmlns:ListRecords/xmlns:record)")).to eq(OAISolr::Settings.page_size)
    end

    describe "resumption tokens" do
      it "provides resumption token" do
        token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0]
        expect(token.text).not_to be(nil)
      end

      it "resumption token has complete list size" do
        token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0]
        expect(token.attributes["completeListSize"].value).to match(/^\d+/)
      end

      it "when given a bad solr cursorMark, gives an oai bad resumption token error" do
        get oai_endpoint, verb: "ListRecords", resumptionToken: "marc21.s(hathitrust:pdus).f(2013-08-01T00:00:00Z).u(2022-12-15T17:27:25Z):500-1000-nonsense"
        expect(doc.xpath("count(//xmlns:error[@code='badResumptionToken'])")).to eq(1)
      end

      it "gets a valid ruby OAI token from first page" do
        first_page_token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0].text
        expect(first_page_token).to start_with("oai_dc")
      end

      it "gets a valid ruby OAI token from second page" do
        first_page_token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0].text
        get oai_endpoint, verb: "ListRecords", resumptionToken: first_page_token

        _doc, resumption_token, _ids = doc_token_ids(last_response.body)
        expect(resumption_token).to start_with("oai_dc")
      end

      it "gives different results per page" do
        _doc1, token1, ids1 = doc_token_ids(last_response.body)
        get oai_endpoint, verb: "ListRecords", resumptionToken: token1
        _doc2, token2, ids2 = doc_token_ids(last_response.body)
        get oai_endpoint, verb: "ListRecords", resumptionToken: token2
        _doc3, token3, ids3 = doc_token_ids(last_response.body)

        total_ids = ids1.size + ids2.size + ids3.size
        expect(total_ids).to eq(OAISolr::Settings.page_size * 3)
        expect([token1, token2, token3].uniq.size).to eq(3)
        expect([ids1, ids2, ids3].flatten.uniq.size).to eq(total_ids)
      end

      it "single page of results has no resumptionToken element" do
        # should have only one record in sample set
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: "2013-08-01", until: "2013-08-01"

        expect(doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")).to be_empty
      end

      # http://www.openarchives.org/OAI/openarchivesprotocol.html#FlowControl
      # "the response containing the incomplete list that completes the list must include an empty resumptionToken element;"
      it "last page includes empty resumptionToken" do
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: "2013-08-10", until: "2013-08-10"
        _doc1, token1, _ids1 = doc_token_ids(last_response.body)
        get oai_endpoint, verb: "ListRecords", resumptionToken: token1
        _doc2, token2, _ids2 = doc_token_ids(last_response.body)
        expect(token2).to eq("")
      end

      it "when given a bad set, gives an oai noRecordsMatch error" do
        get oai_endpoint, verb: "ListRecords", set: "hathitrust:nonexistent", metadataPrefix: "marc21"
        expect(doc.xpath("count(//xmlns:error[@code='noRecordsMatch'])")).to eq(1)
      end
    end

    describe "date range query" do
      it "can limit by until" do
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", until: min_htid_update.iso8601
        token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0]
        limited_list_size = token.attributes["completeListSize"].value
        expect(limited_list_size.to_i).to be < total_docs
      end

      it "can limit by from and until" do
        date = min_htid_update
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: (date - 30).iso8601, until: (date + 7).iso8601
        token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0]
        limited_list_size = token.attributes["completeListSize"].value
        expect(limited_list_size.to_i).to be < total_docs
      end

      it "can limit by more granular timestamps" do
        date = min_htid_update
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: (date - 30).strftime("%FT%TZ"), until: (date + 7).strftime("%FT%TZ")
        token = doc.xpath("//xmlns:ListRecords/xmlns:resumptionToken")[0]
        limited_list_size = token.attributes["completeListSize"].value
        expect(limited_list_size.to_i).to be < total_docs
      end

      # This is a vagary of the sample data, where all items indexed there have
      # the same max update date, so we can't do a "from" limit and see
      # anything between 0 and the full set
      it "with from in the future, gives no results" do
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: (Date.today + 1).iso8601
        error = doc.xpath("//xmlns:error")[0]
        expect(error.attributes["code"].value).to eq("noRecordsMatch")
      end

      it "with until > from, gives no results" do
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: (max_htid_update + 1).iso8601, until: (max_htid_update - 1).iso8601
        error = doc.xpath("//xmlns:error")[0]
        expect(error.attributes["code"].value).to eq("noRecordsMatch")
      end

      it "includes deleted records" do
        del_date = deleted_document_date
        get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", from: del_date, until: del_date
        deleted = doc.xpath("//xmlns:record/xmlns:header[@status='deleted']")
        expect(deleted.count).to be > 0
      end
    end

    it "can get the complete result set"

    it_behaves_like "valid oai response"
  end

  describe "ListRecords in hathitrust:pd set" do
    before(:each) { get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", set: "hathitrust:pd" }
    it_behaves_like "valid oai response"

    it "provides a page of N results" do
      expect(doc.xpath("count(//xmlns:ListRecords/xmlns:record)")).to eq(OAISolr::Settings.page_size)
    end

    it "does not include non-pd volumes" do
      expect(doc.xpath("count(//marc:datafield[@tag='856']/marc:subfield[@code='r'][normalize-space(text())='ic' or normalize-space(text())='und' or normalize-space(text())='pdus'])", ns_map)).to be == 0
      expect(doc.xpath("count(//marc:datafield[@tag='856']/marc:subfield[@code='r'][normalize-space(text())='pd'])", ns_map)).to be > 0
    end
  end

  describe "ListRecords in hathitrust:pdus set" do
    before(:each) { get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", set: "hathitrust:pdus" }
    it_behaves_like "valid oai response"

    it "provides a page of N results" do
      expect(doc.xpath("count(//xmlns:ListRecords/xmlns:record)")).to eq(OAISolr::Settings.page_size)
    end

    it "does not include non-pd/non-pdus volumes" do
      expect(doc.xpath("count(//marc:datafield[@tag='856']/marc:subfield[@code='r'][normalize-space(text())='ic' or normalize-space(text())='und'])", ns_map)).to be == 0
      expect(doc.xpath("count(//marc:datafield[@tag='856']/marc:subfield[@code='r'][normalize-space(text())='pd' or normalize-space(text())='pdus'])", ns_map)).to be > 0
    end
  end

  describe "ListRecords in hathitrust set" do
    before(:each) { get oai_endpoint, verb: "ListRecords", metadataPrefix: "marc21", set: "hathitrust" }
    it_behaves_like "valid oai response"

    it "provides a page of N results" do
      expect(doc.xpath("count(//xmlns:ListRecords/xmlns:record)")).to eq(OAISolr::Settings.page_size)
    end

    it "includes ic volumes" do
      expect(doc.xpath("count(//marc:datafield[@tag='856']/marc:subfield[@code='r'][normalize-space(text())='ic' or normalize-space(text())='und'])", ns_map)).to be > 0
    end
  end

  describe "GetRecord DublinCore" do
    before(:each) { get oai_endpoint, verb: "GetRecord", metadataPrefix: "oai_dc", identifier: existing_record["id"] }
    it_behaves_like "valid oai response"

    it "isn't duplicating records" do
      first_title = /<dc:title>(.*)<.dc:title>/.match(last_response.body)[1]
      id = solr_client.get("select", params: solr_params.merge(rows: 2))["response"]["docs"][1]["id"]
      get oai_endpoint, verb: "GetRecord", metadataPrefix: "oai_dc", identifier: id
      second_title = /<dc:title>(.*)<.dc:title>/.match(last_response.body)[1]
      expect(first_title).to_not eq(second_title)
    end
  end

  describe "GetRecord MARC" do
    before(:each) { get oai_endpoint, verb: "GetRecord", metadataPrefix: "marc21", identifier: existing_record["id"] }
    it_behaves_like "valid oai response"

    it "can get a record as MARC" do
      record = MARC::XMLReader.new(StringIO.new(last_response.body)).first
      expect(record.leader).to match(/[\dA-Za-z ]{23}/)
    end
  end

  describe "GetRecord with nonexistent identifier" do
    it "returns oai idDoesNotExist error" do
      get oai_endpoint, verb: "GetRecord", metadataPrefix: "oai_dc", identifier: "nonexistent"
      error = doc.xpath("//xmlns:error")[0]
      expect(error.attributes["code"].value).to eq("idDoesNotExist")
    end

    it "can handle post requests" do
      post oai_endpoint, verb: "GetRecord", metadataPrefix: "oai_dc", identifier: "nonexistent"
      error = doc.xpath("//xmlns:error")[0]
      expect(error.attributes["code"].value).to eq("idDoesNotExist")
    end
  end
end
