require "oai_solr/settings"
require "canister"

module OAISolr
  Services = Canister.new
  Services.register(:sets) do
    Settings.sets.map { |k, v| [k.to_s, OAISolr::RestrictedSet.new(k.to_s, v)] }.to_h
  end
end
