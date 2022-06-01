require "oai"

module OAISolr
  class DublinCore < OAI::Provider::Metadata::DublinCore
    def encode _, record
      dc_hash = record.marc_record.to_dublin_core
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
  end
end
