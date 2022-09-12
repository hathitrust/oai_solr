# frozen_string_literal: true

module OAISolr
  class Set
    attr_reader :name, :spec, :filter_query, :filter_xpath

    SET_NAMES = {
      "hathitrust:pd" => "Public domain and open access works viewable worldwide",
      "hathitrust:pdus" => "Public domain works according to copyright law in the United States"
    }.freeze

    SET_FILTER_QUERIES = {
      "hathitrust:pd" => ["ht_searchonly:false", "ht_searchonly_intl:false"],
      "hathitrust:pdus" => ["ht_searchonly:false", "ht_searchonly_intl:true"]
    }.freeze

    # xpaths for identifying irrelevant HT ids and removing them from the containing MARC XML
    SET_FILTER_XPATHS = {
      "hathitrust:pd" => "//xmlns:datafield[@tag='974']/xmlns:subfield[@code='r'][normalize-space(text())!='pd']",
      "hathitrust:pdus" => "//xmlns:datafield[@tag='974']/xmlns:subfield[@code='r'][normalize-space(text())!='pdus' and normalize-space(text())!='pd']"
    }.freeze

    def self.for_spec(set_spec = nil)
      set_spec.nil? ? Set.new : RestrictedSet.new(set_spec)
    end

    def initialize
      @spec = ""
      @name = ""
      @filter_query = []
      @filter_xpath = nil
    end
  end

  class RestrictedSet < Set
    def initialize(set_spec)
      raise "Unknown set #{set_spec}" unless SET_NAMES.key? set_spec

      @spec = set_spec
      @name = SET_NAMES[set_spec]
      @filter_query = SET_FILTER_QUERIES[set_spec]
      @filter_xpath = SET_FILTER_XPATHS[set_spec]
    end
  end
end
