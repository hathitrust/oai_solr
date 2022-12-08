require "spec_helper"
require "oai_solr/provider"

RSpec.describe OAISolr::Provider do
  let(:provider) { described_class.new }

  describe "#identifier" do
    it "should return a 9-digit number" do
      expect(provider.identifier).to match(/^\d{9}/)
    end

    it "has granularity YYYY-MM-DD" do
      expect(provider.granularity).to eq("YYYY-MM-DD")
    end
  end
end
