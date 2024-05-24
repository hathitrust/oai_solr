require "marc"
require "oai"

module OAISolr
  class Marc21Full
    ZEPHIR_FIELDS = %w[DAT CAT CID HOL FMT].to_set

    def prefix
      "marc21_full"
    end

    def schema
      "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    end

    def namespace
      "http://www.loc.gov/MARC21/slim"
    end

    def encode _, record
      record.marc_record.tap do |r|
        r.fields.reject! { |f| ZEPHIR_FIELDS.include?(f.tag) }
      end.to_xml_string(fast_but_unsafe: true, include_namespace: true)
    end
  end
end
