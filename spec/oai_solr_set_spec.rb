require "spec_helper"
require "oai_solr/set"
require "nokogiri"

RSpec.describe OAISolr::Set do
  shared_examples "a valid Set" do
    it "has a name" do
      expect(set.name).to be_instance_of(String)
    end

    it "has a spec" do
      expect(set.spec).to be_instance_of(String)
    end

    it "has a filter query array" do
      expect(set.filter_query).to be_instance_of(Array)
    end
  end

  shared_examples "a valid RestrictedSet" do
    it_behaves_like "a valid Set"

    it "has a nonempty spec" do
      expect(set.spec.length).to be > 0
    end
  end

  describe "Set" do
    let(:set) { OAISolr::Set.new }
    it_behaves_like "a valid Set"

    it "has an empty spec" do
      expect(set.spec).to eq("")
    end

    it "has no restrictions on rights codes" do
      expect(set.excluded_rights_codes.count).to equal 0
    end
  end

  describe "RestrictedSet" do
    describe "#new" do
      it "raises on unknown spec" do
        expect { described_class.for_spec("hathitrust:invalid") }.to raise_error(StandardError)
      end
    end

    describe "RestrictedSet with hathitrust:pd" do
      let(:set) { OAISolr::Set.for_spec "hathitrust:pd" }
      it_behaves_like "a valid RestrictedSet"

      it "has the same spec it was created with" do
        expect(set.spec).to eq("hathitrust:pd")
      end

      it "has a set of restricted rights codes" do
        expect(set.excluded_rights_codes.count).to be > 0
        expect(set.excluded_rights_codes).to include("pdus")
      end
    end

    describe "RestrictedSet with hathitrust:pdus" do
      let(:set) { OAISolr::Set.for_spec "hathitrust:pdus" }
      it_behaves_like "a valid RestrictedSet"

      it "has the same spec it was created with" do
        expect(set.spec).to eq("hathitrust:pdus")
      end

      it "has a set of restricted rights codes" do
        expect(set.excluded_rights_codes.count).to be > 0
        expect(set.excluded_rights_codes).not_to include("pdus")
      end
    end

    describe "RestrictedSet with hathitrust" do
      let(:set) { OAISolr::Set.for_spec "hathitrust" }
      it_behaves_like "a valid RestrictedSet"

      it "has the same spec it was created with" do
        expect(set.spec).to eq("hathitrust")
      end

      it "has a set of restricted rights codes" do
        expect(set.excluded_rights_codes.count).to be > 0
        expect(set.excluded_rights_codes).not_to include("ic")
      end
    end
  end
end
