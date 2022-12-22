require "oai"
require "rights_database"

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

    def self.rights_statement(record, statements = access_statements(record))
      template = <<~RIGHTS_STATEMENT_TEMPLATE
        Items in this record are available %{head_statement}.
        View the access and use profile %{url_statement}.
        Please see individual items for rights and use statements.
      RIGHTS_STATEMENT_TEMPLATE
      head_statement = conjunctionalize statements.map { |statement| "as #{statement.head}" }
      url_statement = conjunctionalize statements.map { |statement| "at #{statement.url}" }
      statement = template % {head_statement: head_statement, url_statement: url_statement}
      statement.gsub!(/[[:space:]]+/, " ").strip!
    end

    private

    def dublin_core_hash(record)
      # TODO: to_dublin_core doesn't do much in the current release of ruby-marc
      record.marc_record.to_dublin_core.compact.tap do |dc|
        dc.default_proc = proc { |hash, key| hash[key] = [] }

        dc["type"] = "text"
        dc["date"] = record.solr_document["display_date"]
        dc["description"] = description(record)
        dc["rights"] = self.class.rights_statement(record)

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

    # Returns an array of unique access statements for each HTID on record
    # If the query has an associated set, exclude any item with rights not
    # covered by the set.
    private_class_method def self.access_statements(record)
      statements = ::Set.new
      record.marc_record.fields("974").each do |field|
        rights_attr = field["r"]
        access_profile = access_profile(field["c"], field["s"])

        statements.add Services.rights_database.access_statements_map.map[[rights_attr, access_profile]]
      end
      statements.to_a.sort_by(&:head)
    end

    private_class_method def self.access_profile(collection, digitizer)
      access_profile_code = Services.access_profiles[[collection, digitizer]]
      Services.rights_database.access_profiles[access_profile_code].name
    end

    # Utility method for rights_statement.
    # Turns ["public domain", "in-copyright", "something"] into
    # "public domain, in-copyright, and something"
    private_class_method def self.conjunctionalize(array = nil)
      return "" if array.nil? || array.length.zero?
      return array.join(" and ") if array.length <= 2
      array[0..-2].join(", ") + ", and " + array[-1]
    end
  end
end
