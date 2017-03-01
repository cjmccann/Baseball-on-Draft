class Team
  attr_accessor :data_manager, :batters, :pitchers, :batter_slots, :pitcher_slots, :avg_percentiles
  

  def initialize(data_manager)
    @data_manager = data_manager
    @batters = { }
    @pitchers = { }
    @avg_percentiles = { }

    @batter_slots = { "C" => 2, "1B" => 1, "2B" => 1, "3B" => 1, "SS" => 1,
                          "CI" => 1, "MI" => 1, "LF" => 1, "CF" => 1, "RF" => 1,
                          "OF" => 2, "UTIL" => 2 }
    @pitcher_slots = { "SP" => 4, "RP" => 3, "P" => 3 }
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
    else
      puts "No available team slot for: #{player.name} (#{player.position})."
    end
  end

  def register_batter_slot(player, slot)
    index = 1

    while(!@batters[slot + "-" + index.to_s].nil?)
      index += 1
    end

    @batters[slot + "-" + index.to_s] = player.name
    @batter_slots[slot] -= 1
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
end
