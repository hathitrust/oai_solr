# frozen_string_literal: true

module OAISolr
  class Set
    attr_reader :name, :spec, :filter_query, :exclusion_filter

    SET_NAMES = {
      "hathitrust:pd" => "Public domain and open access works viewable worldwide",
      "hathitrust:pdus" => "Public domain works according to copyright law in the United States"
    }.freeze

    SET_FILTER_QUERIES = {
      "hathitrust:pd" => ["ht_searchonly:false", "ht_searchonly_intl:false"],
      "hathitrust:pdus" => ["ht_searchonly:false", "ht_searchonly_intl:true"]
    }.freeze

    # Exclusion filters: xpaths for irrelevant HTIDs that can be removed from the containing MARC.
    # Note: 'umall' is no longer a valid rights attribute but is included here for completeness
    # as it still has an entry in ht_rights.attributes
    SET_PD_EXCLUSION_FILTER = <<~SET_PD_EXCLUSION_FILTER
      //xmlns:datafield[@tag='974']/xmlns:subfield[@code='r'][normalize-space(text())='ic'
      or normalize-space(text())='op'
      or normalize-space(text())='orph'
      or normalize-space(text())='und'
      or normalize-space(text())='umall'
      or normalize-space(text())='nobody'
      or normalize-space(text())='pdus'
      or normalize-space(text())='orphcand'
      or normalize-space(text())='und-world'
      or normalize-space(text())='icus'
      or normalize-space(text())='pd-pvt'
      or normalize-space(text())='supp'
      ]
    SET_PD_EXCLUSION_FILTER

    SET_PDUS_EXCLUSION_FILTER = <<~SET_PDUS_EXCLUSION_FILTER
      //xmlns:datafield[@tag='974']/xmlns:subfield[@code='r'][normalize-space(text())!='pdus']
    SET_PDUS_EXCLUSION_FILTER

    SET_EXCLUSION_FILTERS = {
      "hathitrust:pd" => SET_PD_EXCLUSION_FILTER,
      "hathitrust:pdus" => SET_PDUS_EXCLUSION_FILTER
    }.freeze

    def self.for_spec(set_spec = nil)
      set_spec.nil? ? Set.new : RestrictedSet.new(set_spec)
    end

    def initialize
      @spec = ""
      @name = ""
      @filter_query = []
      @exclusion_filter = nil
    end
  end

  class RestrictedSet < Set
    def initialize(set_spec)
      raise "Unknown set #{set_spec}" unless SET_NAMES.key? set_spec

      @spec = set_spec
      @name = SET_NAMES[set_spec]
      @filter_query = SET_FILTER_QUERIES[set_spec]
      @exclusion_filter = SET_EXCLUSION_FILTERS[set_spec]
    end
  end
end
