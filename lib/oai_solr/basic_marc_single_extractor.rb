module OAISolr
  # Build up a simple object to quasi-efficiently extract values from MARC tag/subfield-codes
  # based on a simplistic query specification.
  #
  # A single BasicMARCSingleExtractor will extract a specific set of subfields from the
  # given tag specification.
  #
  # The set (or single) of tags_to_match you want can be passed in as:
  #   * A single string. `"245"`
  #   * A three digit integer, which will be coerced into a string. `245`
  #     * Note that if you want a zero-led field (e.g., "050") you can't use the integer option
  #   * An array of tags_to_match. ["245", "100", "111"]
  #   * A range of Strings that encompass all the tags you want,. "600".."699"
  #
  # Subfield codes can be expressed as:
  #   * A string containing all the subfields you want. "abdek"
  #   * A range of one-character strings. "a".."n"
  #
  # Control field: for "codes", pass a range of characters to fetch
  #   * When dealing with a control field, the "codes" passed should actually be a range of integers
  #     corresponding to the indexes (zero-based) of the characters you want from that value.
  class BasicMARCSingleExtractor
    # Generally, MARC fields have the data in alphabetical subfields fields, and metadata (e.g., links to
    # other fields) in numbered subfields.  We'll use all the "letter" subfields as the
    # default for which subfields to use.
    ALPHA = "a".."z"

    attr_reader :tags, :codes, :computed_tags

    # Create a new extractor for the given tag(s) and subfield code(s)
    # Note that this code just creates a method to determine if a field matches the desired tags_to_match,
    # and another to actually extract data from the subfields of those matched fields.
    #
    # Everything else in this class is just support to create the #matches_tag? and
    # #extract methods.
    #
    # @param [String, Array<String>, Range<String>] tags
    # @param [String] codes A list of the
    # @example One field tag, two subfield codes
    #   extractor = BasicMARCSingleExtractor.new("245", "ab")
    # @example An array of tags_to_match
    #   extractor = BasicMARCSingleExtractor.new(["100", "110", "111"], "abd")
    # @example A range of tags_to_match, and the default (all alphabetic) subfield codes
    #   extractor = BasicMARCSingleExtractor.new("600".."699") # subfield codes defaults to ALPHA
    # @example A single tag, with a range of subfields
    #   extractor = BasicMARCSingleExtractor.new("245", "a".."e")
    # @example Get the "date1" characters from the 008 field
    #   extractor = BasicMARCStringExtractor.new("008", 7..10)
    def initialize(tags, codes)
      @tags = tags
      @codes = codes || ALPHA
      define_singleton_method(:matches_tag?, tag_matcher(@tags))
      define_singleton_method(:extract, value_extractor(@codes))
    end

    # @!method matches_tag?(tag)
    #   Determines if the passed field tag (e.g., "245") is one that this extractor
    #   cares about.
    #   @param [String] tag
    #   @return [Boolean]

    # @!method extract(field)
    #   Takes a MARC::DataField or MARC::ControlField and:
    #     * get the values of the subfields with the wanted codes and
    #       return them as a single, space-delimited string
    #     * Get a range of characters from a control field, when the "codes" specified was
    #       actually an integer range.
    #   @param [MARC::DataField, MARC::ControlField] field
    #   @return [String] the desired value(s), with subfield values joined with a space

    # If the "codes" that were passed was actually an integer range, we assume that we're dealing
    # with a control field.
    def control_field?
      codes.is_a?(Range) and codes.begin.is_a?(Integer)
    end

    # Try to extract strings from the desired subfield values. If none match, or we end
    # up with an empty string, return nil
    # @param [MARC::DataField] field
    # @return [String, nil] Space-delimited values of the wanted subfields
    def value(field)
      val = if matches_tag?(field.tag)
        extract(field) # defined dynamically in the constructor
      else
        return nil
      end

      val.empty? ? nil : val
    end

    # To decide what values to extract, we first need to decide if a given field's tag
    # is one of the ones we care about for this extractor.
    #
    # Use the tag specification passed in the constructor and figure out
    # the best way to test if a field tag string (e.g., "245") matches the tags
    # covered by this extractor. Then build a lambda that will do that test.
    #
    # The returned lambda is used in the constructor to create the #matches_tag? method
    # @param  [String, Array<String>, Range<String>] tags_to_match
    # @return [Proc] a lambda that takes a single tag and sees if it matches this extractor
    def tag_matcher(tags_to_match)
      case tags_to_match
      when Integer, String
        @computed_tags = tags_to_match.to_s
        ->(t) { t.to_s == @computed_tags }
      when Array
        @computed_tags = tags_to_match.map(&:to_s).uniq
        ->(t) { @computed_tags.include? t }
      when Range
        @computed_tags = tags_to_match
        ->(t) { @computed_tags.cover?(t) }
      else
        raise "Illegal argumrnt '#{tags_to_match.inspect}'"
      end
    end

    # Given a subfield codes specification from the constructor, build an efficient
    # lambda to pull out the data from the given code(s) as a string. Used in the
    # constructor to make the #extract method.
    # @param [String, Range<String>, Range<Integer>] codes_or_control_field_range
    # @return [Proc] lambda that take a MARC::ControlField or MARC::DataField and pulls
    #   out the requested data.
    def value_extractor(codes_or_control_field_range)
      if control_field?
        control_field_extractor(codes_or_control_field_range)
      else
        datafield_extractor(codes_or_control_field_range)
      end
    end

    private

    # A control field extractor just gets the characters in the given range
    # @param [Range] integer_range  Integer range (zero-based) of the chars you want
    # @return [Proc] lambda that will take a control field and extract the right characters
    def control_field_extractor(integer_range)
      ->(control_field) { control_field.value.slice(integer_range) }
    end

    # Subfield extraction for when the codes are specified as a single char, a bunch of chars,
    # or a char range.  Each is treated separately to get the best performance for
    # each situation, because these things can add up when doing lots and lots of records.
    # @param [String] codes A string of which subfield codes to extract
    # @return [Proc] lambda that will correctly do the extraction and joining of values on the passed field.
    def datafield_extractor(codes)
      case codes
      when String
        if codes.size == 1
          ->(data_field) { data_field.select { |sf| sf.code == codes }.map(&:value).join(" ").strip }
        else
          codesarray = codes.chars
          ->(data_field) { data_field.select { |sf| codesarray.include? sf.code }.map(&:value).join(" ").strip }
        end
      when Range
        ->(data_field) { data_field.select { |sf| codes.cover? sf.code }.map(&:value).join(" ").strip }
      else
        raise "Subfield codes must be either a string of chars, a range of chars, or a range of ints for control field extraction"
      end
    end
  end
end
