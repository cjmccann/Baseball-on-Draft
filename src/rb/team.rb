require 'deep_clone'

class Team
  attr_accessor :data_manager, :batters, :pitchers, :batter_slots, :pitcher_slots, :team_percentiles
  
  def initialize(data_manager)
    @data_manager = data_manager
    @batters = { }
    @pitchers = { }
    @team_percentiles = { :bat => { }, :pit => { } }

    store_league_settings()
  end

  def store_league_settings
    @batter_slots = { "C" => 2, "1B" => 1, "2B" => 1, "3B" => 1, "SS" => 1,
                      "CI" => 1, "MI" => 1, "LF" => 1, "CF" => 1, "RF" => 1,
                      "OF" => 2, "UTIL" => 2 }

    @pitcher_slots = { "SP" => 4, "RP" => 3, "P" => 3 }

    @target_stats = {
      :bat => [:r, :hr, :rbi, :sb, :avg],
      :pit => [:w, :sv, :so, :era, :whip]
    }
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


  def simulate_add_player(player)

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
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
    end
  end

  def update_team_percentiles(player)
    player.stats[:percentiles].each do |category, percentile|
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

    player.stats[:percentiles].each do |category, percentile|
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
end
