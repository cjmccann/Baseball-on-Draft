require 'deep_clone'

require_relative 'league_settings'

class Team
  attr_accessor :batters, :pitchers, :batter_slots, :pitcher_slots, :team_percentiles, :target_stats
  
  def initialize(data_manager)
    @data_manager = data_manager
    @batters = { }
    @pitchers = { }
    @team_percentiles = { :bat => { }, :pit => { } }

    store_league_settings()
  end

  def store_league_settings
    @target_stats = LeagueSettings.get_stats
    @initial_batter_slots = LeagueSettings.get_positions[:bat]
    @initial_pitcher_slots = LeagueSettings.get_positions[:pit]
    @batter_slots = @initial_batter_slots.clone
    @pitcher_slots = @initial_pitcher_slots.clone
  end

  def get_target_percentiles(team_percentiles)
    target_percentiles = { :bat => { }, :pit => { } }

    @target_stats.each do |type, categories|
      categories.each do |category|
        if team_percentiles[type].empty?
          target_percentiles[type][category] = 0.0
        else
          target_percentiles[type][category] = team_percentiles[type][category][:avg_percentile]
        end
      end
    end

    target_percentiles
  end

  def add_player(player)
    if player.type == :bat
      add_batter(player)
    elsif player.type == :pit
      add_pitcher(player)
    else
      puts "Player with unknown @type: #{player.type}"
    end
  end

  def add_batter(player)
    slot = get_available_batter_slot(player.position)

    if !slot.nil?
      register_batter_slot(player, slot)
      player.set_drafted
      update_team_percentiles(player)
      @data_manager.update_cumulative_stats
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
    end
  end

  def add_pitcher(player)
    slot = get_available_pitcher_slot(player.position)

    if !slot.nil?
      register_pitcher_slot(player, slot)
      player.set_drafted
      update_team_percentiles(player)
      @data_manager.update_cumulative_stats
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
    end
  end

  def update_team_percentiles(player)
    player.stats[:initial_percentiles].each do |category, percentile|
      update_percentile(@team_percentiles, player.type, category, percentile)
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
        percentile_deltas[:deltas][type][category] = delta
      end
    end

    percentile_deltas
  end

  def get_percentile_delta(type, category, value)
    init_percentile(@team_percentiles, type, category) if @team_percentiles[type][category].nil?

    value - @team_percentiles[type][category][:avg_percentile]
  end

  def get_simulated_team_percentiles(player)
    team_percentile_clone = DeepClone.clone(@team_percentiles)

    player.stats[:initial_percentiles].each do |category, percentile|
      update_percentile(team_percentile_clone, player.type, category, percentile)
    end

    team_percentile_clone
  end


  def register_batter_slot(player, slot)
    index = 1

    while(!@batters[slot + "-" + index.to_s].nil?)
      index += 1
    end

    @batters[slot + "-" + index.to_s] = player.name
    @batter_slots[slot] -= 1
  end

  def register_pitcher_slot(player, slot)
    index = 1

    while(!@pitchers[slot + "-" + index.to_s].nil?)
      index += 1
    end

    @pitchers[slot + "-" + index.to_s] = player.name
    @pitcher_slots[slot] -= 1
  end

  def get_available_batter_slot(pos)
    return pos if @batter_slots[pos] > 0

    if pos == "1B" || pos == "3B"
      return "CI" if @batter_slots["CI"] > 0
    end

    if pos == "2B" || pos == "SS"
      return "MI" if @batters_slots["MI"] > 0
    end

    if pos == "LF" || pos == "CF" || pos == "RF"
      return "OF" if @batter_slots["OF"] > 0
    end

    if @batter_slots["UTIL"] > 0
      return "UTIL"
    end

    return nil
  end

  def get_available_pitcher_slot(pos)
    return pos if @pitcher_slots[pos] > 0

    if pos == "SP" || pos == "RP"
      return "P" if @pitcher_slots["P"] > 0
    end

    return nil
  end

  def remaining_positional_impact(pos)
    if @initial_pitcher_slots.include?(pos)
        return (0.1) * (@pitcher_slots[pos] / @initial_pitcher_slots[pos])

    elsif @initial_batter_slots.include?(pos)
      initial_aux_slots = 0
      cur_aux_slots = 0

      if pos == "1B" || pos == "3B"
        initial_aux_slots += @initial_batter_slots["CI"]
        cur_aux_slots += @batter_slots["CI"]
      elsif pos == "2B" || pos == "SS"
        initial_aux_slots += @initial_batter_slots["MI"]
        cur_aux_slots += @batter_slots["MI"]
      end

      current_slots = @batter_slots[pos] + cur_aux_slots
      initial_slots = @initial_batter_slots[pos] + initial_aux_slots

      return (0.1) * (current_slots / initial_slots).to_f
    end
  end

  def print_team_percentiles
    puts "-------------------------"
    puts "Team Average Percentiles"
    puts "-------------------------"
    puts "Batting:"

    target_percentiles = get_target_percentiles(@team_percentiles)
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

  # TODO: improve print detailed
  def print_detailed()
    puts @batters
    puts @pitchers
  end

  def print_basic()
    puts @batters
    puts @pitchers
  end

  def total_batter_slots_remaining()
    sum = 0

    @batter_slots.each do |_, slots|
      sum += slots
    end
  end

  def total_pitcher_slots_remaining()
    sum = 0

    @pitcher_slots.each do |_, slots|
      sum += slots
    end
  end
end
