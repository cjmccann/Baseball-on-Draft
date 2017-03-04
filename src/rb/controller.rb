require_relative 'projection_parser'
require_relative 'data_manager'
require_relative 'team'

class Controller
  attr_accessor :options, :data_manager, :team, :other_teams, :batters, :pitchers, :all_players, :league_size

  def initialize(options)
    parser = ProjectionParser.new(options)
    @data_manager = DataManager.new(parser)

    @team = Team.new(@data_manager)
    @batters = parser.batters
    @pitchers = parser.pitchers
    @all_players = @batters.merge(@pitchers) do |key, oldval, newval|
      puts "## Found duplicate player '#{key}'! ##"
      newval
    end
    @league_size = 10

    @other_teams = []

    (league_size - 1).times do
      @other_teams.push(Team.new(@data_manager))
    end
  end

  def main_loop()
    while(true)
      player_added = false

      while(!player_added)
        puts ""
        puts "-------------------------------------------------"
        puts "What do you want to do? (Input number to select.)"
        puts "  1. Add a player to your team."
        puts "  2. Add a player to another team."
        puts "  3. Display top 25 available players. (Relative to current team)"
        puts "  4. Display top 25 available players for position. (Relative to current team)"
        puts "  5. Display top 25 available players. (Absolute)"
        puts "  6. Display top 25 available players for position. (Absolute)"
        puts "  7. Display top 25 available players. (Position adjusted)"
        puts "  8. Display my team."
        puts "  X. Display other team."
        puts "  X. Display all other teams."
        puts "  8. Display all drafted players."
        puts "  9. binding.pry"
        puts "  0. Exit."
        puts "-------------------------------------------------"
        print ">>> "

        player_added = handle_response(gets.chomp)

        @data_manager.update_cumulative_stats if player_added
      end
    end
  end

  def handle_response(response)
    case response
    when "1"
      puts "Player name?"
      info = get_more_info(response)

      if info[:player_valid]
        player = get_player_with_name(info[:name])
        @team.add_player(player)
        true
      else
        puts "Player invalid: #{info[:name]}"
        false
      end

    when "2"
      puts "Player name?"
      info = get_more_info(response)

      if info[:player_valid]
        player = get_player_with_name(info[:name])
        @other_teams[info[:team_no].to_i].add_player(player)
        true
      else
        puts "Player invalid: #{info[:name]}"
        false
      end
    when "3"
      sorted_players = get_sorted_players_list()
      print_players(sorted_players, 25)
      false
    when "4"
      puts ""
      puts "Which position?"
      sorted_players = get_sorted_players_list(get_more_info(response)[:pos])
      print_players(sorted_players, 25)
      false
    when "5"
      sorted_players = get_sorted_players_list_absolute_percentiles()
      print_players(sorted_players, 25)
      false
    when "6"
      puts ""
      puts "Which position?"
      sorted_players = get_sorted_players_list_absolute_percentiles(get_more_info(response)[:pos])
      print_players(sorted_players, 25)
      false
    when "7"
      sorted_players = get_sorted_players_list_with_pos_adjustments()
      print_players(sorted_players, 25)
      false
    when "8"
      @team.print_detailed()
      false
    when "9"
      binding.pry
      false
    when "0"
      exit
    else
      false
    end
  end

  def get_more_info(response)
    print ">>> "
    next_response = gets.chomp
    info = { }

    if response == "1" || response == "2"
      if is_valid_player?(next_response)
        info[:player_valid] = true
      else
        info[:player_valid] = false
      end
    end

    case response
    when "1"
      info[:name] = next_response
    when "2"
      info[:name] = next_response
      puts ""
      puts "Which team? 0 - #{@league_size}"
      print ">>> "
      info[:team_no] = gets.chomp
    when "4", "6"
      info[:pos] = next_response
    end

    return info
  end

  def is_valid_player?(a_name)
    @all_players.each do |name, player|
      if a_name == name
        return true
      end
    end

    return false
  end

  def get_player_with_name(a_name)
    @all_players.each do |name, player|
      if a_name == name
        return player
      end
    end
  end

  def get_sorted_players_list(pos = nil)
      player_values = { }

      @all_players.each do |name, player|
        unless player.is_drafted?
          if pos.nil? || player.matches_position?(pos)
            player_values[name] = { :value => @team.get_target_percentile_deltas_with_new_player(player)[:deltas_magnitude], :player => player }
          end
        end
      end

      return player_values.sort_by { |name, obj| (-1) * obj[:value] } 
  end 

  def get_sorted_players_list_absolute_percentiles(pos = nil)
    player_values = { } 

    @all_players.each do |name, player|
      unless player.is_drafted?
        if pos.nil? || player.matches_position?(pos)
          player_values[name] = { :value => player.get_absolute_percentile_sum(@team.target_stats), :player => player }
        end
      end
    end

    return player_values.sort_by { |name, obj| (-1) * obj[:value] }
  end

  def get_sorted_players_list_with_pos_adjustments(pos = nil)
    set_positional_adjustments()
    player_values = { } 

    @all_players.each do |name, player|
      unless player.is_drafted?
        if pos.nil? || player.matches_position?(pos)
          next if @positional_adjustments[player.position].nil? 
          player_values[name] = { :value => player.get_absolute_percentile_sum(@team.target_stats) * @positional_adjustments[player.position], 
                                  :player => player }
        end
      end
    end

    return player_values.sort_by { |name, obj|  (-1) * obj[:value] }
  end

  def set_positional_adjustments()
    volatilities = { :bat => { }, :pit => { } }
    @positional_adjustments = { }
    subset_size = 10


    @team.batter_slots.each do |pos, _|
      # TODO: Excluding RF/LF/CF due to league settings, only need OF slots
      next if pos == "CI" || pos == "MI" || pos == "UTIL" || pos == "RF" || pos == "LF" || pos == "CF"
      volatilities[:bat][pos] = get_volatility_for_position(pos, subset_size)
    end

    @team.pitcher_slots.each do |pos, _|
      next if pos == "P"
      volatilities[:pit][pos] = get_volatility_for_position(pos, subset_size)
    end

    avg_batter_volatility = volatilities[:bat].values.reduce(0, :+) / volatilities[:bat].length
    avg_pitcher_volatility = volatilities[:pit].values.reduce(0, :+) / volatilities[:pit].length

    volatilities[:bat].each do |pos, value|
      @positional_adjustments[pos] = (value / avg_batter_volatility)
    end

    volatilities[:pit].each do |pos, value|
      @positional_adjustments[pos] = (value / avg_pitcher_volatility)
    end
  end

  def get_volatility_for_position(pos, n)
    sorted_players_subset = get_sorted_players_list_absolute_percentiles(pos).slice(0, n)
    players = { }

    sorted_players_subset.each do |elem|
      players[elem[0]] = elem[1][:player]
    end

    if !players.empty?
      type = players.values[0].type
    else
      # TODO: Do this better, get type in some other way.
      puts "Players list is empty when getting variance."
    end

    @data_manager.get_volatility_for_players(players, @team.target_stats[type])
  end

  def print_players(players, n)
    i = 0

    puts ""
    puts "-----------------------------------------"
    puts "Player | Cumulative percentile difference"
    puts "-----------------------------------------"
    while i < n
      puts " #{(i + 1).to_s}. " + players[i][0] + " | " + players[i][1][:value].to_s
      i += 1
    end
  end
end
