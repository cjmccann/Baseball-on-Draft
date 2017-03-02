require 'pry'
require 'json'
require 'optparse'

require_relative './rb/projection_parser'
require_relative './rb/data_manager'
require_relative './rb/team'

options = { }
OptionParser.new do |opts|
  opts.on('--forceProjectionProcessing') do 
    options[:forceProjectionProcessing] = true
  end

  opts.on('--forceAliasProcessing') do
    options[:forceAliasProcessing] = true
  end

  opts.on('--help') do
    puts opts
    exit
  end
end

parser = ProjectionParser.new(options)
data_manager = DataManager.new(parser)
team = Team.new(data_manager)

while(true)
  player_values = { }
  parser.batters.each do |name, player|
    unless player.is_drafted?
      player_values[name] = team.get_target_percentile_deltas_with_new_player(player)[:deltas_magnitude]
    end
  end

  parser.pitchers.each do |name, player|
    unless player.is_drafted?
      player_values[name] = team.get_target_percentile_deltas_with_new_player(player)[:deltas_magnitude]
    end
  end

  sorted_players = player_values.sort_by { |name, deltas_magnitude| (-1) * deltas_magnitude } 
  sorted_players.inspect
  binding.pry
end
