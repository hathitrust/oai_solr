require "oai_solr/settings"
require "canister"

module OAISolr
  Services = Canister.new

  Services.register(:sets) do
    Settings.sets.map { |k, v| [k.to_s, OAISolr::RestrictedSet.new(k.to_s, v)] }.to_h
  end

  Services.register(:rights_database) do
    RightsDatabase
  end

  Services.register(:access_profiles) do
    RightsDatabase::DB.connection[:ht_collection_digitizers]
      .map { |v| [[v[:collection], v[:digitization_source]], v[:access_profile]] }
      .to_h
  end
end
