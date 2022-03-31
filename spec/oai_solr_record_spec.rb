require "rspec"
require "oai_solr/model"

RSpec.describe "OAISolr::Record" do
  describe "#to_oai_dc" do
    it "provides valid dublin core"
    it "has dc:title"
    it "has dc:creator"
    it "has dc:type text"
    it "has dc:publisher"
    it "has dc:date"
    it "has dc:language"
    it "has dc:format"
    it "has dc:description"
    it "has dc:identifier"
    it "has dc:rights"
  end

  describe "to_marc21" do
    it "provides valid marc"
    it "simplifies the MARC metadata"
  end
end
