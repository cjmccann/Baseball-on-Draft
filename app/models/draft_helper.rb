Dir[File.join(Rails.root, 'lib', 'stats', '**', '*.rb')].each { |f| require_dependency f }

class DraftHelper < ActiveRecord::Base
  after_create :generate_stats

  belongs_to :league
  belongs_to :user

  has_one :setting_manager, through: :league
  has_one :data_manager
  has_many :teams, through: :league
  has_many :players, dependent: :destroy, autosave: false

  def regenerate
  end

  def pitchers
    Player.where( { draft_helper: self, player_type: "pit" } )
  end

  def batters
    Player.where( { draft_helper: self, player_type: "bat" } )
  end

  def all_players
    Player.where( { draft_helper: self } )
  end

  private
  def generate_stats
    LeagueSettings.set_league_settings(self.league.setting_manager.convert_all_settings_to_hash)
    parser = ProjectionParser.new(self)
    data_manager = self.build_data_manager( { draft_helper: self, league: self.league, user: self.user,
                                              target_stats: LeagueSettings.get_stats, 
                                              batter_slots: LeagueSettings.get_positions[:bat],
                                              pitcher_slots: LeagueSettings.get_positions[:pit] } )
    binding.pry
    data_manager.batters = parser.batters.values
    data_manager.pitchers = parser.pitchers.values
    data_manager.save
    self.save
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
