# frozen_string_literal: true

require "ettin"

module OAISolr
end

OAISolr::Settings = Ettin.for(Ettin.settings_files("config", settings.environment))
OAISolr::Settings.environment = settings.environment
