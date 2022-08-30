require "nokogiri"
require "oai"
require "rsolr"
require "oai_solr/record"
require "oai_solr/set"

module OAISolr
  class Model < OAI::Provider::Model
    include OAI::Provider

    def earliest
      Time.at(0)
    end

    def latest
      Time.now
    end

    def sets
      Settings.sets.map { |spec| OAISolr::Set.new(spec: spec.to_s) }
    end

    def find(selector, opts = {})
      @client = RSolr.connect url: ENV.fetch("SOLR_URL", "http://localhost:9033/solr/catalog")
      if selector == :all
        find_all(opts)
      else
        find_one(selector, opts)
      end
    end

    private

    def find_all(opts)
      (cursor_mark, opts) = restore_options(opts)

      params = {
        q: "*:*",
        wt: "ruby",
        rows: Settings.page_size,
        cursorMark: cursor_mark,
        sort: "id asc"
      }
      unless opts[:set].nil?
        set = OAISolr::Set.new(spec: opts[:set])
        params[:fq] = set.fq
      end
      response = @client.get("select", params: params)

      OAI::Provider::PartialResult.new(
        response["response"]["docs"].map { |doc| OAISolr::Record.new(prune_doc(doc, opts[:set])) },
        resumption_token(opts, response)
      )
    end

    # Returns the cursorMark to use for the solr query along with options as
    # parsed from a resumption token
    def restore_options(opts)
      if opts[:resumption_token]
        token = OAI::Provider::ResumptionToken.parse(opts[:resumption_token])
        [token.last_str, token.to_conditions_hash]
      else
        ["*", opts]
      end
    end

    def find_one(selector, opts)
      response = @client.get "select", params: {q: "id:#{selector}", wt: "ruby"}
      OAISolr::Record.new(response["response"]["docs"].first)
    end

    def resumption_token(opts, response)
      OAI::Provider::ResumptionToken.new(
        opts.merge(last: response["nextCursorMark"]),
        nil,
        response["response"]["numFound"]
      )
    end

    # Remove 974 datafield for any HT volumes that do not belong in the set, if any.
    def prune_doc(doc, spec)
      return doc if spec.nil?

      xml = Nokogiri::XML::Document.parse(doc["fullrecord"])
      pd_xpath = "//xmlns:datafield[@tag='974']/xmlns:subfield[@code='r'][normalize-space(text())!='pd']"
      pdus_xpath = "//xmlns:datafield[@tag='974']/xmlns:subfield[@code='r'][normalize-space(text())!='pdus' and normalize-space(text())!='pd']"
      xpath = spec == "hathitrust:pd" ? pd_xpath : pdus_xpath
      nodes = xml.xpath(xpath)
      nodes.each { |node| node.parent.remove }
      doc["fullrecord"] = xml.to_xml
      doc
    end
  end
end
