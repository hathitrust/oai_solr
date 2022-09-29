require "oai"

module OAISolr
  class DublinCore < OAI::Provider::Metadata::DublinCore
    def encode _, record
      dc_hash = dublin_core_hash(record)

      xml = Builder::XmlMarkup.new
      xml.tag!("#{prefix}:#{element_namespace}", header_specification) do
        fields.each do |field|
          if dc_hash.has_key? field.to_s
            [dc_hash[field.to_s]].flatten.each do |value|
              xml.tag! "#{element_namespace}:#{field}", value
            end
          end
        end
      end
      xml.target!
    end

    private

    def dublin_core_hash(record)
      # TODO: to_dublin_core doesn't do much in the current release of ruby-marc
      record.marc_record.to_dublin_core.compact.tap do |dc|
        dc.default_proc = proc { |hash, key| hash[key] = [] }

        dc["type"] = "text"
        dc["date"] = record.solr_document["display_date"]
        dc["description"] = description(record)
        dc["rights"] = rights_statement

        %w[publisher language format]
          .reject { |k| record.solr_document[k].nil? }
          .each { |k| dc[k] = [record.solr_document[k]].flatten }

        record.solr_document["oclc"]&.each { |o| dc["identifier"] << "(OCoLC)#{o}" }
        record.solr_document["ht_id"].each { |htid| dc["identifier"] << "#{Settings.handle}#{htid}" }
        record.solr_document["isbn"]&.each { |isbn| dc["identifier"] << isbn }
      end.reject { |_k, v| v.nil? || v.empty? }
    end

    # Current implementation appears to use 300
    # ruby-marc's next release will likely use 500
    def description(record)
      return unless record.marc_record["300"]

      record.marc_record["300"].subfields.select { |sub| %w[a b c].include? sub.code }.map { |sub| sub.value }.join(" ")
    end

    # TODO: I don't know how this is being generated currently and for records with multiple
    # items it doesn't make much sense.
    def rights_statement
      "a rights statement"
    end
  end
end
