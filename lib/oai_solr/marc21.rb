require "marc"
require "oai"

module OAISolr
  class Marc21
    SLIM_MARC_FIELDS = {"010": "a", "015": "a", "020": "a", "022": "a",
                        "035": "a", "041": "ah", "050": "ab", "082": "ab",
                        "100": "abcdq", "110": "ab", "111": "ab", "130": "ab",
                        "240": "a", "245": "abc", "250": "ab",
                        "260": "abc", "265": "abc", "300": "a", "600": "abcdqxyz",
                        "610..699": "axyz"}

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
      slim_marc(record.marc_record).to_xml_string(fast_but_unsafe: true, include_namespace: true)
    end

    # Duplicate the record with only some of the fields
    # https://docs.google.com/spreadsheets/d/12Geu1Dst-frCNBA9kRwhAAK2yTI_qjl-deEt91P6S6k
    #
    # @param [MARC::Record]
    # @return [MARC::Record]
    def slim_marc full_marc
      @slim_marc = MARC::Record.new
      # TODO: Do something about field "899" which is specd but not valid
      @slim_marc.leader = full_marc.leader
      full_marc.fields
        .select { |f| f.is_a? MARC::ControlField }
        .each { |f| @slim_marc << f }
      SLIM_MARC_FIELDS.each do |tag, subfield_codes|
        add_field(full_marc, symbol_to_tag(tag), subfield_codes.chars)
      end
      full_marc.each_by_tag("974") { |field| @slim_marc << field974_to_field856(field) }
      @slim_marc
    end

    private

    # @param [MARC::Field]
    # @return [MARC::Field]
    def field974_to_field856(field974)
      MARC::DataField.new("856", "4", "1",
        ["u", Settings.handle + field974["u"]],
        ["z", field974["z"]],
        ["x", "eContent"],
        ["r", field974["r"]])
    end

    # @param [MARC::Record]
    # @param [String]
    # @param [Array]
    def add_field(full_marc, tag, subfield_codes)
      full_marc.each_by_tag(tag) do |field|
        new_field = MARC::DataField.new(field.tag, field.indicator1, field.indicator2)
        field.each do |subfield|
          new_field.append(subfield) if subfield_codes.include? subfield.code
        end
        @slim_marc << new_field if new_field.subfields.any?
      end
    end

    def symbol_to_tag tag_symbol
      if (m = tag_symbol.to_s.match(/^(\d{3})..(\d{3})$/))
        # it's a range
        m[1]..m[2]
      else
        tag_symbol.to_s
      end
    end
  end
end
