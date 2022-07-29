require "oai"
require "pry"

module OAISolr
  class DublinCore < OAI::Provider::Metadata::DublinCore
    def encode _, record
      @record = record
      xml = Builder::XmlMarkup.new
      xml.tag!("#{prefix}:#{element_namespace}", header_specification) do
        fields.each do |field|
          if dublin_core_hash.has_key? field.to_s
            [dublin_core_hash[field.to_s]].flatten.each do |value|
              xml.tag! "#{element_namespace}:#{field}", value
            end
          end
        end
      end
      xml.target!
    end

    def dublin_core_hash
      # TODO: to_dublin_core doesn't do much in the current release of ruby-marc
      @dc = @record.marc_record.to_dublin_core.compact
      @dc.default_proc = proc { |hash, key| hash[key] = [] }
      @dc["type"] = "text"
      %w[publisher language format].each do |key|
        @dc[key] = [@record.solr_document[key]].flatten
      end
      @dc["date"] = @record.solr_document["display_date"]
      @dc["description"] = description
      @dc["rights"] = rights_statement
      @record.solr_document["oclc"]&.each { |o| @dc["identifier"] << "(OCoLC)#{o}" }
      @record.solr_document["ht_id"].each { |htid| @dc["identifier"] << "#{Settings.handle}#{htid}" }
      @dc
    end

    private

    # Current implementation appears to use 300
    # ruby-marc's next release will likely use 500
    def description
      @record.marc_record["300"].subfields.select { |sub| %w[a b c].include? sub.code }.map { |sub| sub.value }.join(" ")
    end

    # TODO: I don't know how this is being generated currently and for records with multiple
    # items it doesn't make much sense.
    def rights_statement
      "a rights statement"
    end
  end
end
