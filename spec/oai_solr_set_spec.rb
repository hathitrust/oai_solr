require "rspec"
require "oai_solr/set"

RSpec.describe OAISolr::Set do
  shared_examples "a valid set" do
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
  let(:set) { described_class.new(spec: "hathitrust:pd") }

  describe "Set" do
    let(:set) { OAISolr::Set.new }
    it_behaves_like "a valid set"

    it "has an empty spec" do
      expect(set.spec).to eq("")
    end

    it "has a nil filter xpath" do
      expect(set.filter_xpath).to be_nil
    end
  end

  describe "RestrictedSet" do
    let(:set) { OAISolr::Set.for_spec "hathitrust:pd" }
    it_behaves_like "a valid set"

    it "has the same spec it was created with" do
      expect(set.spec).to eq("hathitrust:pd")
    end

    it "has a filter xpath String" do
      expect(set.filter_xpath).to be_instance_of(String)
    end

    describe "#new" do
      it "raises on unknown spec" do
        expect { described_class.for_spec("hathitrust:invalid") }.to raise_error(StandardError)
      end
    end
  end
end
