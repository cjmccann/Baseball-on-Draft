Dir[File.join(Rails.root, 'lib', 'stats', '**', '*.rb')].each { |f| require_dependency f }

class DraftHelper < ActiveRecord::Base

  after_create :set_drafted_player_id_hashes, :generate_relative_stats

  belongs_to :league
  belongs_to :user

  has_one :setting_manager, through: :league
  has_one :data_manager
  has_many :teams, through: :league

  serialize :drafted_player_ids, Hash
  serialize :drafted_player_ids_by_team, Hash

  def regenerate
  end

  def pitchers
    Player.where( { player_type: "pit" } )
  end

  def batters
    Player.where( { player_type: "bat" } )
  end

  def all_players
    Player.all
  end

  private
  def set_drafted_player_id_hashes
    drafted_player_ids_by_team_temp = { }

    self.league.teams do |team|
      drafted_player_ids_by_team_temp[team.name] = [ ]
    end

    self.drafted_player_ids_by_team = drafted_player_ids_by_team_temp
    self.drafted_player_ids = { }
  end

  def generate_relative_stats
    LeagueSettings.set_league_settings(self.league.setting_manager.convert_all_settings_to_hash)
    data_manager = self.build_data_manager( { draft_helper: self, league: self.league, user: self.user,
                                              target_stats: LeagueSettings.get_stats, 
                                              batter_slots: LeagueSettings.get_positions[:bat],
                                              pitcher_slots: LeagueSettings.get_positions[:pit] } )
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
