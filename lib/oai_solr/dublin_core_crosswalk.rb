require_relative "basic_marc_extractor"

module OAISolr
  # Create an instance that will map MARC records to Dublin Core fields.
  # Generally taken from the crosswalk at https://www.loc.gov/marc/marc2dc.html
  # Mappings that can be easily specified as an OAI::BasicMARCExtractor are defined
  # in the MAPPINGS constant. Anything more complex has its own method.
  class DublinCoreCrosswalk
    MAPPINGS = {

      contributor: [
        [%w[100 700], "abcdjq"],
        [%w[110 710], "abcd"],
        [%w[111 711], "acden"],
        ["720", "a"]
      ],

      coverage: [
        [651, nil],
        [662, nil],
        [751, nil],
        [752, nil]
      ],

      # date -- see below

      description: [
        [["300"] + ("500".."599").to_a - %w[506 530 538 540 546], nil]
      ],

      format: [
        [340, nil],
        [856, "q"]
      ],

      identifier: [
        [%w[020 022 024], "a"],
        [856, "u"],
        [%w[050 080 060], nil],
        ["082", "ab"]
      ],

      language: [
        ["008", 35..37],
        ["041", "abdefghj"]
      ],

      publisher: [
        ["260", "ab"]
      ],

      relation: [
        ["530", nil],
        [("760".."787"), "ot"]
      ],

      rights: [
        ["506", nil],
        ["540", nil]
      ],

      source: [
        ["534", "t"],
        ["540", nil],
        ["786", "ot"]
      ],
      subject: [
        ["600", "abcdefghjklmnopqrstuvxyz"],
        ["610", "abcdefghklmnoprstuvxyz"],
        ["611", "acdefghjklnpqstuvxyz"],
        ["630", "adefghklmnoprstvxyz"],
        ["650", "abcdevxyz"],
        ["653", "abevyz"]
      ],

      title: [
        ["245", "abdefgknp"],
        ["246", "abdefgknp"]
      ]

      # type -- see below
    }

    MAPPINGS.each do |key, spec_pairs|
      bme = BasicMARCExtractor.from_pairs(spec_pairs)
      define_method(key.to_sym, ->(rec) { bme.values(rec) })
    end

    # If it's necessary to add a field that does not have an identically-named
    # accessor, or is not in MAPPINGS, some adjustment may be necessary,
    def full_map(rec)
      fields = MAPPINGS.keys + %i[type date]
      fields.map { |field| [field, send(field, rec)] }
        .to_h.reject { |k, v| v.empty? }
    end

    # Get the best date possible, looking for four digits in the 008, then
    # falling back to the 260cg
    # @param [MARC::Record] rec
    def date(rec)
      possible_year = date_008(rec)
      return possible_year if /\A\d{4}\Z/.match?(possible_year)

      other_possible_date = date_260cg(rec)

      if /\S/.match?(other_possible_date)
        other_possible_date
      else
        possible_year
      end
    end

    def type(rec)
      leader6 = rec.leader[6]
      leader7 = rec.leader[7]
      types = []
      types << "text" if %w[a c d t].include?(leader6)
      types << "image" if %w[e f g k].include?(leader6)
      types << "sound" if %w[i k].include?(leader6)
      types << "collection" if (leader6 == "p") || %w[c s].include?(leader7)
      types
    end

    private

    def date_008(rec)
      rec["008"].value[7..10]
    end

    def date_260cg(rec)
      two_sixty = rec["260"]
      if two_sixty
        [two_sixty["c"], two_sixty["g"]].join(" ")
      end
    end
  end
end
