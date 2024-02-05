# frozen_string_literal: true

require_relative "basic_marc_single_extractor"

module OAISolr
  # A collection of BasicMARCSingleExtractors that will collect their combined values from
  # a MARC::Record.
  class BasicMARCExtractor
    # Create a new object, optionally passing tags/codes to add a first BasicMARCSingleExtractor
    # @param [String,Array<String>,Range<String>] tags Single, array or, or range over 3-digit marc tags
    # @param [String, Range<String>] subfield_codes Either a single string with all the desired subfield codes
    #   e.g., "abcek", or a range, e.g., "'a'..'m'". Optional.
    # @example
    #   bme = BasicMARCExtractor.new; bme << BasicMARCSingleExtractor.new("245", "ab")
    #   bme = BasicMARCExtractor.new("245", "ab")
    #   bme = BasicMARCExtractor.new("600".."699", "a".."z")
    def initialize(tags = nil, subfield_codes = nil)
      @single_extractors = []
      if tags
        self << BasicMARCSingleExtractor.new(tags, subfield_codes)
      end
    end

    # Given an array of duples (as from config), build up an extractor using `#<<`
    # @param [Array<Array<String>>] tag_code_pairs Array of arrays of the form [ [tags, subfield_codes], ...]
    # @example
    #   bme = BasicMARCExtractor.from_pairs([["245", "ab"], ["100".."111", "abd"]])
    # @see OAI::BasicMARCSingleExtractor#initialize for supported syntax
    def self.from_pairs(tag_code_pairs)
      unless tag_code_pairs.first&.is_a?(Array)
        raise "#{self.class}.from_pairs takes an array of arrays"
      end
      basic_marc_extractor = new
      tag_code_pairs.each { |tag, codes| basic_marc_extractor << BasicMARCSingleExtractor.new(tag, codes) }
      basic_marc_extractor
    end

    # Add a previously constructed single extractor, and re-compute the set of interesting tags
    # @param [OAI::BasicMARCSingleExtractor] basic_marc_single_extractor
    # @return [OAI::BasicMARCExtractor]
    def <<(basic_marc_single_extractor)
      @single_extractors << basic_marc_single_extractor
      set_interesting_tags!
      self
    end

    # For efficiently, keep track of which field tags are "interesting" to this specific extractor,
    # so we don't have to check the whole list of field tags for every BasicMARCSingleExtractor
    # @see set_interesting_tags!
    # @param [String] tag The field tag
    # @return [Boolean]
    def interesting_tag?(tag)
      @interesting_ranges.any? { |rng| rng.cover?(tag) } or @interesting_single_tags.include?(tag)
    end

    # Get a list of the "interesting" fields (by tag), and run each single extractor in turn
    # on them. Flatten, compact, and uniq the resulting strings and return
    # @param [MARC::Record] rec The record from which to extract data
    # @return [Array<String>] array of extracts
    def values(rec)
      rec.select { |field| interesting_tag?(field.tag) }
        .flat_map { |f| @single_extractors.flat_map { |extractor| extractor.value(f) } }
        .compact.uniq
    end

    private

    # We want to efficiently determine if the tag is one that we're interested in.
    # We support single tags, arrays of (single) tags, and tag ranges. The first two
    # merge into one set; the ranges we handle separately for efficiency (no sense in
    # turning '600'..'699' into an array)
    def set_interesting_tags!
      @interesting_single_tags = ::Set.new
      @interesting_ranges = ::Set.new
      @single_extractors.map(&:computed_tags).each do |tags|
        case tags
        when Range
          @interesting_ranges << tags
        else
          @interesting_single_tags += Array(tags)
        end
        @interesting_single_tags.flatten!
      end
    end
  end
end
