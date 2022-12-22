# frozen_string_literal: true

require "oai_solr/services"

module OAISolr
  class NonexistentSetError < RuntimeError; end

  # A Set is an unrestricted (i.e., no filtering) specification for
  # a group of records. It holds logic to both change a record
  # to fit the specification (e.g., remove all non-open holdings)
  # and to filter out records that don't conform (e.g., a record
  # that has no holdings at all).
  class Set
    # @return [String] The "name" (more like description) of the set
    attr_reader :name
    # @return [String] The key for this specification (e.g., "hathitrust:pd")
    attr_reader :spec
    # @return [Array<String>] Possibly-empty list of filter queries
    attr_reader :filter_query
    # @return [Array<String>] Possibly-empty list of rights codes not allowed in this set
    attr_reader :excluded_rights_codes

    # @return [Array<String>] List of set keys as defined in the settings
    # VALID_SET_SPECS = Settings.sets.keys.map(&:to_s)

    # @param [String] set_spec Key of the set specification
    # @return [OAISolr::Set, OAISolr::RestrictedSet]
    def self.for_spec(set_spec = nil)
      (set_spec.nil? ? Set.new : Services.sets[set_spec]).tap do |s|
        raise NonexistentSetError.new("Unknown set #{set_spec}") unless s
      end
    end

    def initialize
      @spec = ""
      @name = ""
      @filter_query = []
      @excluded_rights_codes = []
    end

    # Take a record and remove/change fields to conform to what you want
    # to return for a given set.
    # @param [OAISolr::Record] rec Record to potentially munch
    # @return [OAISolr::Record] Munged record
    def remove_unwanted_974s(rec)
      # no filtering for full set
      rec
    end

    # Do we want to keep this record in the set, or throw it away?
    # @param [OAISolr::Record] rec Record to potentially munch
    # @return [Boolean] Whether this record conforms to the restrictions of the set
    def include_record?(rec)
      true
    end
  end

  # A set that has restrictions derived from the Settings
  class RestrictedSet < Set
    # @param [String] set_spec The key of the spec in the settings
    # @raise [ArgumentError] if the set_spec isn't found in the settings
    def initialize(set_spec, config)
      #      raise NonexistentSetError.new("Unknown set #{set_spec} not in #{VALID_SET_SPECS.join(", ")}") unless VALID_SET_SPECS.include? set_spec
      #      config = Settings.sets[set_spec]
      @spec = set_spec
      @name = config.name
      @filter_query = config.filter_query.map { |k, v| "#{k}:#{v}" }
      @predicate = ->(r) { config.filter_query.all? { |k, v| r.solr_document[k.to_s] == v } }
      @excluded_rights_codes = config.excluded_rights
    end

    def remove_unwanted_974s(r)
      return r if r.deleted?
      r.remove_fields! { |f| f.tag == "974" and excluded_rights_codes.include?(f["r"]) }
      r
    end

    def include_record?(r)
      r.deleted? || !r.marc_record["974"].nil?
    end

    def filter_query_matches(r)
      @predicate.call(r)
    end
  end
end
