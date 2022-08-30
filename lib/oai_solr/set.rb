module OAISolr
  class Set
    attr_reader :name, :spec

    SET_NAMES = {"hathitrust:pd" => "Public domain and open access works viewable worldwide",
                 "hathitrust:pdus" => "Public domain works according to copyright law in the United States"}.freeze
    SET_FQS = {"hathitrust:pd" => ["ht_searchonly:false", "ht_searchonly_intl:false"],
               "hathitrust:pdus" => ["ht_searchonly:false", "ht_searchonly_intl:true"]}.freeze

    def initialize(spec:)
      raise "Unknown set #{spec}" unless SET_NAMES.key? spec

      @spec = spec
      @name = SET_NAMES[spec]
    end

    def fq
      @fq ||= SET_FQS[@spec]
    end
  end
end
