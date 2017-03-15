Dir[File.join(Rails.root, 'lib', 'stats', '**', '*.rb')].each { |f| require_dependency f }

class DraftHelper < ActiveRecord::Base
  after_save :generate_stats

  belongs_to :league
  belongs_to :user

  has_one :setting_manager
  has_one :data_manager
  has_many :teams
  has_many :players, dependent: :destroy

  attr_accessor :data_manager

  def regenerate
  end

  def pitchers
    Player.where( { league: self.league, player_type: "pit" } )
  end

  def batters
    Player.where( { league: self.league, player_type: "bat" } )
  end

  def all_players
    Player.where( { league: self.league } )
  end

  private
  def generate_stats
    LeagueSettings.set_league_settings(self.league.setting_manager.convert_all_settings_to_hash)
    parser = ProjectionParser.new(self)
    save_players(parser.batters)
    save_players(parser.pitchers)
    data_manager = self.build_data_manager( { draft_helper: self, league: self.league, user: self.user,
                                              target_stats: LeagueSettings.get_stats, 
                                              batter_slots: LeagueSettings.get_positions[:bat],
                                              pitcher_slots: LeagueSettings.get_positions[:pit] } )
    data_manager.save
  end

  def save_players(players)
    players.values.each do |player|
      if player.save

      else
        puts "Could not save player #{player.name}."
      end
    end
  end
end
