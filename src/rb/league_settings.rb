require 'yaml'

class LeagueSettings
  def self.load_default_settings
    settings_path = File.expand_path(File.dirname(__FILE__) + '/../data/league_settings.yml')

    @@settings = YAML.load_file(settings_path)
  end

  def self.get_positions
    return @@settings[:positions]
  end

  def self.get_stats
    return @@settings[:stats]
  end
end
