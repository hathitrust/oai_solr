require "oai"
require "rights_database"
require "oai_solr/dublin_core_crosswalk"

module OAISolr
  class DublinCore < OAI::Provider::Metadata::DublinCore
    # A dublic core crosswalk object for translating MARC records into
    # the dublin core fields.
    CROSSWALK = OAISolr::DublinCoreCrosswalk.new

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

    # @param [OAISolr::Record] record
    def dublin_core_hash(record)
      dc = {}

      # Set stuff that's constant for HT items
      dc["type"] = "text"
      dc["rights"] = self.class.rights_statement(record)

      # Get stuff out of the solr documment
      dc["date"] = record.first_solr_value("display_date")
      dc["language"] = record.first_solr_value("language")
      dc["publisher"] = record.first_solr_value("publisher")
      dc["subject"] = record.solr_value("subject_display")
      dc["format"] = record.first_solr_value("format")

      marc = record.marc_record

      # The LoC spec says to NOT use creator, and instead use contributor, but our users
      # have asked that we keep this the same as before, using creator.
      dc["creator"] = CROSSWALK.contributor(marc)

      # Pull the rest from the record according to the Library of Congress crosswalk
      dc["publisher"] ||= CROSSWALK.publisher(marc)
      dc["coverage"] = CROSSWALK.coverage(marc)
      dc["description"] = CROSSWALK.description(marc)
      dc["format"] ||= CROSSWALK.format(marc)
      dc["relation"] = CROSSWALK.relation(marc)
      dc["source"] = CROSSWALK.source(marc)
      dc["title"] = CROSSWALK.title(marc)

      # Get the identifiers
      dc["identifier"] = record.solr_array("oclc").map { |id| "(OCoLC)#{id}" }
        .concat(record.solr_array("ht_id").map { |htid| "#{Settings.handle}#{htid}" })
        .concat(record.solr_array("isbn").map { |isbn| "ISBN #{isbn}" })
        .concat(record.solr_array("issn").map { |issn| "ISBN #{issn}" })
        .concat(record.solr_array("lccn").map { |lccn| "LCCN #{lccn}" })
      # Flatten it all out and get rid of nils and duplicates
      dc.select { |k, v| v.is_a?(Array) }.each_pair do |_field, values|
        values.flatten!
        values.compact!
        values.uniq!
        values.reject! { |x| x == "".freeze }
      end

      # Ditch everything that's empty or nil
      dc.reject! { |_k, v| v.nil? || v.empty? }
      dc
    end

    # Returns an array of unique access statements for each HTID on record
    # If the query has an associated set, exclude any item with rights not
    # covered by the set.
    private_class_method def self.access_statements(record)
      statements = ::Set.new
      record.marc_record.fields("974").each do |field|
        rights_attr = field["r"]
        access_profile = access_profile(field["c"], field["s"])
        if access_profile.nil?
          logger.error "Access profile not found for #{field}"
          next
        end
        statement = Services.rights_database.access_statements_map[attribute: rights_attr, access_profile: access_profile]
        if statement.nil?
          logger.error("Access statement not found for #{field}")
          next
        end
        statements.add statement
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
