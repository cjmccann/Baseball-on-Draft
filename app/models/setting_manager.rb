class SettingManager < ActiveRecord::Base
  before_create :set_default_values
  after_create :create_first_team

  belongs_to :league
  belongs_to :user
  after_save :update_teams

  mattr_accessor :defaults

  self.defaults = { 
    :batter_positions => {
      "bat_C" => 2,
      "bat_1B" => 1,
      "bat_2B" => 1,
      "bat_3B" => 1,
      "bat_SS" => 1,
      "bat_LF" => 0,
      "bat_CF" => 0,
      "bat_RF" => 0,
      "bat_CI" => 1,
      "bat_MI" => 1,
      "bat_OF" => 5,
      "bat_UTIL" => 2 
    }, 
    :pitcher_positions => {
      "pit_SP" => 4,
      "pit_RP" => 2,
      "pit_P" => 4
    },
    :batter_stats => {
      "bat_r" => true,
      "bat_hr" => true,
      "bat_rbi" => true,
      "bat_sb" => true,
      "bat_obp" => true,
      "bat_slg" => true,
      "bat_doubles" => false,
      "bat_bb" => false,
      "bat_so" => false,
      "bat_avg" => false,
      "bat_war" => false
    },
    :pitcher_stats => {
      "pit_sv" => true,
      "pit_hr" => true,
      "pit_so" => true,
      "pit_era" => true,
      "pit_whip" => true,
      "pit_qs" => true,
      "pit_gs" => false,
      "pit_w" => false,
      "pit_l" => false,
      "pit_h" => false,
      "pit_bb" => false,
      "pit_kper9" => false,
      "pit_bbper9" => false,
      "pit_fip" => false,
      "pit_war" => false,
      "pit_dra" => false
    }
  }

  def convert_all_settings_to_hash
    { :positions => convert_positions_to_hash, :stats => convert_stats_to_hash }
  end

  def convert_positions_to_hash
    hash = { :positions => { :bat => { }, :pit => { } } }

    self.defaults[:batter_positions].each do |position, _|
      hash[:positions][:bat][position.split('_')[1]] = self[position]
    end

    self.defaults[:pitcher_positions].each do |position, count|
      hash[:positions][:pit][position.split('_')[1]] = self[position]
    end

    hash[:positions]
  end

  def convert_stats_to_hash
    hash = { :stats => { :bat => [ ], :pit => [ ] } }

    self.defaults[:batter_stats].each do |category, _|
      if self[category]
        hash[:stats][:bat].push(category.split('_')[1].to_sym)
      end
    end

    self.defaults[:pitcher_stats].each do |category, _|
      if self[category]
        hash[:stats][:pit].push(category.split('_')[1].to_sym)
      end
    end


    hash[:stats]
  end

  def get_stats
    convert_stats_to_hash
  end

  def get_positions
    convert_positions_to_hash
  end

  private
  def set_default_values
    self.defaults[:batter_positions].each do |position, count|
      self[position] = count
    end

    self.defaults[:pitcher_positions].each do |position, count|
      self[position] = count
    end

    self.defaults[:batter_stats].each do |category, bool|
      self[category] = bool
    end

    self.defaults[:pitcher_stats].each do |category, bool|
      self[category] = bool
    end
  end

  def create_first_team
    team = self.league.teams.build( { :name => 'My Team', :league => self.league, :user => self.league.user } )
    team.save
  end
end
