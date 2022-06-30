require "marc"
require "oai"

module OAISolr
  class Marc21
    SLIM_MARC_FIELDS = {'010': "a", '015': "a", '020': "a", '022': "a",
                        '035': "a", '041': "ah", '050': "ab", '082': "ab",
                        '260': "abc", '300': "a", '600': "abcdq", '610': "a",
                        '611': "a", '630': "a", '650': "a", '651': "a"}

    def prefix
      "marc21"
    end

    def schema
      "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    end

    def namespace
      "http://www.loc.gov/MARC21/slim"
    end

    def encode _, record
      xml = slim_marc(record.marc_record).to_xml
      xml.root.add_attribute("xsi:schemaLocation", [namespace, schema].join(" "))
      xml.to_s
    end

    # Duplicate the record with only some of the fields
    # @param [MARC::Record]
    # @return [MARC::Record]
    def slim_marc full_marc
      slim_marc = MARC::Record.new
      # TODO: Do something about fields "6XX|xyz" and "899"
      slim_marc.leader = full_marc.leader
      slim_marc << full_marc["005"]
      SLIM_MARC_FIELDS.each do |tag, subfield_codes|
        full_marc.each_by_tag(tag.to_s) do |field|
          new_field = MARC::DataField.new(tag, field["ind1"], field["ind2"])
          field.each do |subfield|
            new_field.append(subfield) if subfield_codes.chars.include? subfield.code
          end
          slim_marc << new_field
        end
      end
      full_marc.each_by_tag("974") { |field| slim_marc << field974_to_field856(field) }
      slim_marc
    end

    private

    # @param [MARC::Field]
    # @return [MARC::Field]
    def field974_to_field856(field974)
      handle = "http://hdl.handle.net/2027/"
      MARC::DataField.new("856", "4", "1",
        ["u", handle + field974["u"]],
        ["z", field974["z"]],
        # TODO: this is an invalid subfield but we were including it previously
        ["r", field974["r"]])
    end
  end
end
