require 'deep_clone'

class Team < ActiveRecord::Base
  belongs_to :league
  belongs_to :user
  
  serialize :batters, Hash
  serialize :pitchers, Hash
  serialize :batter_slots, Hash
  serialize :pitcher_slots, Hash
  serialize :team_percentiles, Hash

  has_many :players

  validates :name, presence: true,
    length: { minimum: 1 }

  before_create :set_default_values

  def set_default_values
    self.batters = { }
    self.pitchers = { }
    self.team_percentiles = { :bat => { }, :pit => { } }

    self.batter_slots = initial_batter_slots.clone
    self.pitcher_slots = initial_pitcher_slots.clone
  end

  def target_stats
    self.league.setting_manager.get_stats
  end

  def initial_batter_slots
    self.league.setting_manager.get_positions[:bat]
  end

  def initial_pitcher_slots
    self.league.setting_manager.get_positions[:pit]
  end

  def draft_helper
    self.league.draft_helper
  end

  def get_target_percentiles(team_percentiles)
    target_percentiles = { :bat => { }, :pit => { } }

    target_stats.each do |type, categories|
      categories.each do |category|
        if team_percentiles[type].empty?
          target_percentiles[type][category] = 0.0
        else
          begin
            if team_percentiles[type][category].nil? 
              target_percentiles[type][category] = 0.0
            else
              target_percentiles[type][category] = team_percentiles[type][category][:avg_percentile]
            end
          rescue Exception
            binding.pry
          end
        end
      end
    end

    target_percentiles
  end

  def add_player(player)
    if player.player_type == "bat"
      add_batter(player)
    elsif player.player_type == "pit"
      add_pitcher(player)
    else
      puts "Player with unknown @type: #{player.player_type}"
    end
  end

  def add_batter(player)
    slot = get_available_batter_slot(player.position)

    if !slot.nil?
      register_batter_slot(player, slot)
      draft_helper.set_drafted(self, player)
      update_team_percentiles(player)
      draft_helper.data_manager.update_cumulative_stats
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
    end
  end

  def add_pitcher(player)
    slot = get_available_pitcher_slot(player.position)

    if !slot.nil?
      register_pitcher_slot(player, slot)
      draft_helper.set_drafted(self, player)
      update_team_percentiles(player)
      draft_helper.data_manager.update_cumulative_stats
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
    end
  end

  def update_team_percentiles(player)
    draft_helper.data_manager.initial_percentiles[player.id].each do |category, percentile|
      update_percentile(self.team_percentiles, player.player_type.to_sym, category, percentile)
    end
  end

  def update_percentile(team_percentiles, type, category, value)
    init_percentile(team_percentiles, type, category) if team_percentiles[type][category].nil?

    data = team_percentiles[type][category]
    data[:values].push(value)
    data[:avg_percentile] = (data[:values].reduce(0, :+)) / data[:values].length
  end

  def init_percentile(team_percentiles, type, category)
    team_percentiles[type][category] = { :avg_percentile => 0.0, :values => [] }
  end

  def get_target_percentile_deltas_with_new_player(player)
    percentile_deltas = { :deltas_magnitude => 0.0, :deltas => { :bat => { }, :pit => { } } }

    sim_team_percentiles = get_simulated_team_percentiles(player)

    simulated_target_percentiles = get_target_percentiles(sim_team_percentiles)
    # percentile_delts[:deltas] = simulated_target_percentiles

    simulated_target_percentiles.each do |type, percentiles|
      percentiles.each do |category, value|
        delta = get_percentile_delta(type, category, value)

        percentile_deltas[:deltas_magnitude] += delta
        percentile_deltas[:deltas][type][category] = delta.round(3)
      end
    end

    percentile_deltas
  end

  def get_percentile_delta(type, category, value)
    init_percentile(self.team_percentiles, type, category) if self.team_percentiles[type][category].nil?

    value - self.team_percentiles[type][category][:avg_percentile]
  end

  def get_simulated_team_percentiles(player)
    team_percentile_clone = DeepClone.clone(self.team_percentiles)

    draft_helper.data_manager.initial_percentiles[player.id].each do |category, percentile|
      update_percentile(team_percentile_clone, player.player_type.to_sym, category, percentile)
    end

    team_percentile_clone
  end


  def register_batter_slot(player, slot)
    index = 1

    while(!self.batters[slot + "-" + index.to_s].nil?)
      index += 1
    end

    self.batters[slot + "-" + index.to_s] = player.id
    self.batter_slots[slot] -= 1
  end

  def register_pitcher_slot(player, slot)
    index = 1

    while(!self.pitchers[slot + "-" + index.to_s].nil?)
      index += 1
    end

    self.pitchers[slot + "-" + index.to_s] = player.id
    self.pitcher_slots[slot] -= 1
  end

  def get_available_batter_slot(pos)
    return pos if self.batter_slots[pos] > 0

    if pos == "1B" || pos == "3B"
      return "CI" if self.batter_slots["CI"] > 0
    end

    if pos == "2B" || pos == "SS"
      return "MI" if self.batters_slots["MI"] > 0
    end

    if pos == "LF" || pos == "CF" || pos == "RF"
      return "OF" if self.batter_slots["OF"] > 0
    end

    if self.batter_slots["UTIL"] > 0
      return "UTIL"
    end

    return nil
  end

  def get_available_pitcher_slot(pos)
    return pos if self.pitcher_slots[pos] > 0

    if pos == "SP" || pos == "RP"
      return "P" if self.pitcher_slots["P"] > 0
    end

    return nil
  end

  def remaining_positional_impact(pos)
    if initial_pitcher_slots.include?(pos)
        return (0.1) * (self.pitcher_slots[pos] / initial_pitcher_slots[pos])

    elsif initial_batter_slots.include?(pos)
      initial_aux_slots = 0
      cur_aux_slots = 0

      if pos == "1B" || pos == "3B"
        initial_aux_slots += initial_batter_slots["CI"]
        cur_aux_slots += self.batter_slots["CI"]
      elsif pos == "2B" || pos == "SS"
        initial_aux_slots += initial_batter_slots["MI"]
        cur_aux_slots += self.batter_slots["MI"]
      end

      current_slots = self.batter_slots[pos] + cur_aux_slots
      initial_slots = initial_batter_slots[pos] + initial_aux_slots

      return (0.1) * (current_slots / initial_slots).to_f
    end
  end

  def print_team_percentiles
    puts "-------------------------"
    puts "Team Average Percentiles"
    puts "-------------------------"
    puts "Batting:"

    target_percentiles = get_target_percentiles(self.team_percentiles)
    target_percentiles[:bat].each do |category, value|
      puts "#{category}: #{value}"
    end

    puts "-------------------------"
    puts "Pitching:"
    target_percentiles[:pit].each do |category, value|
      puts "#{category}: #{value}"
    end
    puts "-------------------------"
  end

  def total_batter_slots_remaining()
    sum = 0

    self.batter_slots.each do |_, slots|
      sum += slots
    end
  end

  def total_pitcher_slots_remaining()
    sum = 0

    self.pitcher_slots.each do |_, slots|
      sum += slots
    end
  end
end
