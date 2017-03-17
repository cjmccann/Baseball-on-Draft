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

  def set_drafted(team, player)
    self.drafted_player_ids_by_team[team.id] = [] if self.drafted_player_ids_by_team[team.id].nil?
    self.drafted_player_ids_by_team[team.id].push(player.id)

    self.drafted_player_ids[player.id] = true
  end

  private
  def set_drafted_player_id_hashes
    self.drafted_player_ids = { }
    self.drafted_player_ids_by_team = { }
  end

  def generate_relative_stats
    data_manager = self.build_data_manager( { draft_helper: self, league: self.league, user: self.user } )
    data_manager.set_default_values
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
