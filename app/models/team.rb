require 'deep_clone'

class Team < ActiveRecord::Base
  belongs_to :league
  belongs_to :user
  
  serialize :batters, Hash
  serialize :pitchers, Hash
  serialize :batter_slots, Hash
  serialize :pitcher_slots, Hash
  serialize :team_percentiles, Hash
  serialize :team_raw_stats, Hash

  has_many :players

  validates :name, presence: true,
    length: { minimum: 1 }

  before_create :set_default_values

  def set_default_values
    self.batters = { }
    self.pitchers = { }
    self.team_percentiles = { :bat => { }, :pit => { } }
    self.team_raw_stats = { :bat => { }, :pit => { } }

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

  def get_slots_with_players()
    batter_positions_filled = { }
    pitcher_positions_filled = { }

    self.batters.each do |slot, id|
      pos = slot.split('-')[0]

      batter_positions_filled[pos] = [] if batter_positions_filled[pos].nil?
      batter_positions_filled[pos].push(id)
    end

    self.pitchers.each do |slot, id|
      pos = slot.split('-')[0]

      pitcher_positions_filled[pos] = [] if pitcher_positions_filled[pos].nil?
      pitcher_positions_filled[pos].push(id)
    end

    slots = { "bat" => [ ], "pit" => [ ] }
    initial_batter_slots.each do |pos, n|
      while (n > 0)
        if (!batter_positions_filled[pos].nil? && !batter_positions_filled[pos].empty?)
          slots["bat"].push( { position: pos, id: batter_positions_filled[pos].shift })
        else
          slots["bat"].push( { position: pos, id: nil } )
        end

        n -= 1
      end
    end

    initial_pitcher_slots.each do |pos, n|
      while (n > 0)
        if (!pitcher_positions_filled[pos].nil? && !pitcher_positions_filled[pos].empty?)
          slots["pit"].push( { position: pos, id: pitcher_positions_filled[pos].shift })
        else
          slots["pit"].push( { position: pos, id: nil } )
        end

        n -= 1
      end
    end

    return slots
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
    # TODO: combine/generalize these blocks... only dependent on differing implementations of get_available_bat/pit_slot
    if player.player_type == "bat"
      if (add_batter(player))
        update_team_percentiles(player)
        update_team_raw_stats(player)
        draft_helper.set_drafted(self, player)
        draft_helper.data_manager.update_cumulative_stats
        draft_helper.data_manager.save
        draft_helper.save
        self.save
        return true
      else
        return false
      end
    else
      if (add_pitcher(player))
        update_team_percentiles(player)
        update_team_raw_stats(player)
        draft_helper.set_drafted(self, player)
        draft_helper.data_manager.update_cumulative_stats
        draft_helper.data_manager.save
        draft_helper.save
        self.save
        return true
      else
        return false
      end
    end
  end

  def remove_player(player)
    update_slots_for_player_removal(player)
    update_team_percentiles_for_player_removal(player)
    update_team_raw_stats_for_player_removal(player)
    draft_helper.set_undrafted(self, player)
    draft_helper.data_manager.update_cumulative_stats

    if (draft_helper.data_manager.save && draft_helper.save && self.save)
      true
    else
      false
    end
  end

  def update_slots_for_player_removal(player)
    positions = nil
    slots = nil

    if player.player_type == 'bat'
      positions = self.batters
      slots = self.batter_slots
    else
      positions = self.pitchers
      slots = self.pitcher_slots
    end

    key_to_remove = nil
    positions.each do |position, player_id|
      if player_id == player.id
        key_to_remove = position
      end
    end

    positions.delete(key_to_remove)

    slot_to_increment = key_to_remove.split('-')[0]
    slots[slot_to_increment] += 1
  end

  def add_batter(player)
    slot = get_available_batter_slot(player.position)

    if !slot.nil?
      register_batter_slot(player, slot)
      return true
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
      return false
    end
  end

  def add_pitcher(player)
    slot = get_available_pitcher_slot(player.position)

    if !slot.nil?
      register_pitcher_slot(player, slot)
      return true
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
      return false
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

  def update_team_percentiles_for_player_removal(player)
    draft_helper.data_manager.initial_percentiles[player.id].each do |category, percentile|
      update_percentile_for_player_removal(self.team_percentiles, player.player_type.to_sym, category, percentile)
    end
  end

  def update_percentile_for_player_removal(team_percentiles, type, category, value)
    data = team_percentiles[type][category]

    # length of array is out of range, so will not delete.
    # this ensures on the first instance of the value is deleted, in case there is more than 1
    data[:values].delete_at(data[:values].index(value) || data[:values].length)
    data[:avg_percentile] = (data[:values].reduce(0, :+)) / data[:values].length
  end

  def update_team_raw_stats_for_player_removal(player)
    draft_helper.data_manager.means[player.id].each do |category, mean|
      update_raw_stat_for_player_removal(self.team_raw_stats, player.player_type.to_sym, category, mean)
    end
  end

  def update_raw_stat_for_player_removal(team_raw_stats, type, category, value) 
    data = team_raw_stats[type][category]

    # see notes in update_percentile_for_player_removal
    data[:values].delete_at(data[:values].index(value) || data[:values].length)
    data[:avg_raw_stat] = (data[:values].reduce(0, :+)) / data[:values].length
  end

  def init_percentile(team_percentiles, type, category)
    team_percentiles[type][category] = { :avg_percentile => 0.0, :values => [] }
  end

  def update_team_raw_stats(player)
    draft_helper.data_manager.means[player.id].each do |category, mean|
      update_raw_stat(self.team_raw_stats, player.player_type.to_sym, category, mean)
    end
  end

  def update_raw_stat(team_raw_stats, type, category, value) 
    init_raw_stat(team_raw_stats, type, category) if team_raw_stats[type][category].nil?

    data = team_raw_stats[type][category]
    data[:values].push(value)
    data[:avg_raw_stat] = (data[:values].reduce(0, :+)) / data[:values].length
  end

  def init_raw_stat(team_raw_stats, type, category)
    team_raw_stats[type][category] = { :avg_raw_stat => 0.0, :values => [] }
  end


  def get_target_percentile_deltas_with_new_player(player, minmax)
    percentile_deltas = { :deltas_magnitude => 0.0, :deltas => { :bat => { }, :pit => { } } }

    sim_team_percentiles = get_simulated_team_percentiles(player)

    simulated_target_percentiles = get_target_percentiles(sim_team_percentiles)
    # percentile_delts[:deltas] = simulated_target_percentiles

    simulated_target_percentiles.each do |type, percentiles|
      percentiles.each do |category, value|
        delta = get_percentile_delta(type, category, value)

        percentile_deltas[:deltas_magnitude] += delta
        percentile_deltas[:deltas][type][category] = delta.round(3)
        
        if percentile_deltas[:deltas][type][category] < minmax[:min]
          minmax[:min] = percentile_deltas[:deltas][type][category]
        elsif percentile_deltas[:deltas][type][category] > minmax[:max]
          minmax[:max] = percentile_deltas[:deltas][type][category]
        end
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
