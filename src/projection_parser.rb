require 'CSV'
require 'pry'

require_relative 'data/model_data'
require_relative 'data/aliases'
require_relative 'player'

class ProjectionParser
  attr_accessor :batters, :pitchers

  def initialize
    Aliases.load_aliases()

    @batters = {}
    @pitchers = {}

    if File.exist?('./data/batters.json') && File.exist?('./data/pitchers.json')
      @batters = JSON.parse(File.read('./data/batters.json')) 
      @pitchers = JSON.parse(File.read('./data/pitchers.json')) 
    else
      read_csv('./projections/bat-steamer.csv', :steamer, :bat, @batters)
      read_csv('./projections/bat-depthcharts.csv', :depthcharts, :bat, @batters)
      read_csv('./projections/bat-pecota.csv', :pecota, :bat, @batters)
      read_csv('./projections/pit-steamer.csv', :steamer, :pit, @pitchers)
      read_csv('./projections/pit-depthcharts.csv', :depthcharts, :pit, @pitchers)
      read_csv('./projections/pit-pecota.csv', :pecota, :pit, @pitchers)

      File.open('./data/batters.json', 'w') do |f|
        f.write(JSON.pretty_generate(@batters))
      end

      File.open('./data/pitchers.json', 'w') do |f|
        f.write(JSON.pretty_generate(@pitchers))
      end
    end

    # Aliases.write_aliases()
  end

  def read_csv(filename, model, type, players)
    skip_header = true

    CSV.foreach(filename) do |row|
      if skip_header
        skip_header = false
        next
      end

      result = nil

      if model == :steamer || model == :depthcharts
        result = players.select { |k, v| k == row[0] }
      elsif model == :pecota
        result = players.select do |k, v| 
          next if row[1].nil? || row[2].nil?

          bool_a = k.include?(row[1]) && k.include?(row[2])

          pecota_name = row[2] + ' ' + row[1]
          bool_b = k.split(' ').reduce(true) { |prev, n| prev && pecota_name.include?(n) }
          
          (bool_a || bool_b)
        end
      end

      if result.empty?
        player = Player.new(row, model, type)
        players[player.name] = player
      else
        result.each do |key, cur_player|
          if model != :pecota
            cur_player.process_data(row, model, type)
          else
            pecota_name = row[2] + " " + row[1]

            if (key == pecota_name)
              cur_player.process_data(row, model, type)
            else
              if Aliases.has_alias?(key, pecota_name)
                cur_player.process_data(row, model, type)
              elsif Aliases.has_exclusion?(key, pecota_name)
                next
              else
                valid_response = false

                while(!valid_response)
                  puts "Is #{key} an alias for #{pecota_name}? y/n"
                  response = gets.chomp

                  if response == 'y'
                    Aliases.add_alias(key, pecota_name)
                    valid_response = true
                  elsif response == 'n'
                    Aliases.add_exclusion(key, pecota_name)
                    valid_response = true
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
