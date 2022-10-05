require "spec_helper"
require "oai_solr/set"

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

    it "has a filter xpath String" do
      expect(set.exclusion_filter).to be_instance_of(String)
    end
  end

  describe "Set" do
    let(:set) { OAISolr::Set.new }
    it_behaves_like "a valid Set"

    it "has an empty spec" do
      expect(set.spec).to eq("")
    end

    it "has a nil filter xpath" do
      expect(set.exclusion_filter).to be_nil
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

      it "produces a working filter xpath" do
        fake_marc_xml = <<~MARC
          <?xml version="1.0" encoding="UTF-8"?>
          <collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/MARC21/slim" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <record>
              <datafield tag="974">
                <subfield code="r">pd</subfield>
              </datafield>
              <datafield tag="974">
                <subfield code="r">ic</subfield>
              </datafield>
              <datafield tag="974">
                <subfield code="r">ic-world</subfield>
              </datafield>
              <datafield tag="974">
                <subfield code="r">cc-by-nc-4.0</subfield>
              </datafield>
              <datafield tag="974">
                <subfield code="r">cc-zero</subfield>
              </datafield>
            </record>
          </collection>
        MARC
        xml = Nokogiri::XML::Document.parse(fake_marc_xml)
        nodes = xml.xpath(set.exclusion_filter)
        # Leave everything but the ic
        expect(nodes.count).to be == 1
      end
    end

    describe "RestrictedSet with hathitrust:pdus" do
      let(:set) { OAISolr::Set.for_spec "hathitrust:pdus" }
      it_behaves_like "a valid RestrictedSet"

      it "has the same spec it was created with" do
        expect(set.spec).to eq("hathitrust:pdus")
      end

      it "produces a working filter xpath" do
        fake_marc_xml = <<~MARC
          <?xml version="1.0" encoding="UTF-8"?>
          <collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/MARC21/slim" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <record>
              <datafield tag="974">
                <subfield code="r">pd</subfield>
              </datafield>
              <datafield tag="974">
                <subfield code="r">pdus</subfield>
              </datafield>
              <datafield tag="974">
                <subfield code="r">ic</subfield>
              </datafield>
            </record>
          </collection>
        MARC
        xml = Nokogiri::XML::Document.parse(fake_marc_xml)
        nodes = xml.xpath(set.exclusion_filter)
        # Filter pd and ic, leave pdus
        expect(nodes.count).to be == 2
      end
    end
  end
end
