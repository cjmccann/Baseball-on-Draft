require_relative 'projection_parser'
require_relative 'data_manager'
require_relative 'team'

class Controller
  attr_accessor :options, :team, :other_teams, :batters, :pitchers, :all_players, :league_size

  def initialize(options)
    parser = ProjectionParser.new(options)
    DataManager.new(parser)

    @team = Team.new()
    @batters = parser.batters
    @pitchers = parser.pitchers
    @all_players = @batters.merge(@pitchers) do |key, oldval, newval|
      puts "## Found duplicate player '#{key}'! ##"
      newval
    end
    @league_size = 10

    @other_teams = []

    (league_size - 1).times do
      @other_teams.push(Team.new())
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
        puts "  3. Display top 25 recommended players."
        puts "  4. Display top 25 recommended players for position."
        puts "  5. Display my team."
        puts "  6. Display other team."
        puts "  7. Display all other teams."
        puts "  0. Exit."
        puts "-------------------------------------------------"

        print ">>> "
        player_added = handle_response(gets.chomp)
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
      puts "Which position?"
      sorted_players = get_sorted_players_list(get_more_info(response)[:pos])
      print_players(sorted_players, 25)
      false
    when "5"
      @team.print_detailed()
      false
    when "6"
      # TODO: add handling for specific team printing
      false 
    when "7"
      @other_teams.each { |team| team.print_basic() }
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
      puts "Which team? 0 - #{@league_size}"
      print ">>> "
      info[:team_no] = gets.chomp
    when "4"
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
            player_values[name] = @team.get_target_percentile_deltas_with_new_player(player)[:deltas_magnitude]
          end
        end
      end

      sorted_players = player_values.sort_by { |name, deltas_magnitude| (-1) * deltas_magnitude } 
      sorted_players
  end 

  def print_players(players, n)
    i = 0

    puts ""
    puts "-----------------------------------------"
    puts "Player | Cumulative percentile difference"
    puts "-----------------------------------------"
    while i < n
      puts "> " + players[i][0] + " | " + players[i][1].to_s
      i += 1
    end
  end
end
