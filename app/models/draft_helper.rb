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

  def set_undrafted(team, player)
    self.drafted_player_ids_by_team[team.id].delete(player.id)
    self.drafted_player_ids[player.id] = false
  end

  def get_color_class(value, minmax)
    td_class = nil

    diff = minmax[:max] - minmax[:min]
    interval = diff / 6

    if value < (minmax[:min] + (interval * 1))
      td_class = "baddest"
    elsif value >= (minmax[:min] + (interval * 1)) && value < (minmax[:min] + (interval * 2))
      td_class = "badder"
    elsif value >= (minmax[:min] + (interval * 2)) && value < (minmax[:min] + (interval * 3))
      td_class = "bad"
    elsif value >= (minmax[:min] + (interval * 3)) && value < (minmax[:min] + (interval * 4))
      td_class = "good"
    elsif value >= (minmax[:min] + (interval * 4)) && value < (minmax[:min] + (interval * 5))
      td_class = "gooder"
    elsif value >= (minmax[:min] + (interval * 5))
      td_class = "goodest"
    end

    td_class
  end

  private
  def set_drafted_player_id_hashes
    self.drafted_player_ids = { }
    self.drafted_player_ids_by_team = { }
  end

  def generate_relative_stats
    data_manager = self.build_data_manager( { draft_helper: self, league: self.league, user: self.user } )
    data_manager.set_initial_values
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
