require 'CSV'
require 'pry'
require 'digest'

require_relative 'model_data'
require_relative 'file_data'
require_relative 'aliases'
require_relative 'league_settings'
# require_relative 'player'

class ProjectionParser
  attr_accessor :batters, :pitchers, :file_digests, :batters_path, :pitchers_path, :digests_path, :draft_helper

  def initialize(draft_helper)
    @draft_helper = draft_helper
    @batters = { }
    @pitchers = { }

    @batters_path = File.expand_path(File.dirname(__FILE__) + '/../data/batters.json')
    @pitchers_path = File.expand_path(File.dirname(__FILE__) + '/../data/pitchers.json')
    @digests_path = File.expand_path(File.dirname(__FILE__) + '/../data/file_digests.json')

    if File.exist?(@digests_path)
      @file_digests = JSON.parse(File.read(@digests_path))
    else
      @file_digests = { }
    end

    Aliases.load_aliases() 

    if File.exist?(@batters_path)
      @batters = convert_json_to_players(JSON.parse(File.read(@batters_path)))
    end

    if File.exist?(@pitchers_path) 
      @pitchers = convert_json_to_players(JSON.parse(File.read(@pitchers_path)))
    end

    FileData.files.each do |filename, props|
      filename = File.expand_path(File.dirname(__FILE__) + '/../' + filename)

      if @file_digests[filename] != Digest::MD5.file(filename).hexdigest
        read_csv(filename, props[:model], props[:type])

      elsif props[:type] == :bat && !File.exist?(@batters_path)
        read_csv(filename, props[:model], props[:type])

      elsif props[:type] == :pit && !File.exist?(@pitchers_path)
        read_csv(filename, props[:model], props[:type])
      end
    end

    clean_player_lists()

    write_parser_data()
  end

  def write_parser_data()
    File.open(@batters_path, 'w') do |f|
      f.write(convert_players_to_json(@batters))
    end

    File.open(@pitchers_path, 'w') do |f|
      f.write(convert_players_to_json(@pitchers))
    end

    File.open(@digests_path,'w') do |f| 
      f.write(JSON.pretty_generate(@file_digests))
    end

    Aliases.write_aliases()
  end

  def convert_players_to_json(players)
    hash = { }

    players.each do |name, value|
      hash[name] = { "position" => value.position, "type" => value.type, "stats" => value.stats }
    end

    return JSON.pretty_generate(hash)
  end

  def convert_json_to_players(json)
    players = { }

    json.each do |name, value|
      # player = Player.new({ :draft_helper_id => @draft_helper, :league_id => @draft_helper.league, :user_id => @draft_helper.user, :is_drafted => false})
      player = @draft_helper.league.players.build({ :league_id => @draft_helper.league, :is_drafted => false, :name => name, :position => value["position"], :player_type => value["type"] })
      player.set_default_values
      player.process_data_from_json(name, value["stats"])
      # player.position = value["position"]
      player.type = value["type"].to_sym
      players[name] = player if player.is_valid?
    end

    return players
  end

  def read_csv(filename, model, type)
    if type == :bat
      players = @batters
    else
      players = @pitchers
    end

    skip_header = true
    CSV.foreach(filename, skip_blanks: true) do |row|
      if skip_header
        skip_header = false
        next
      end

      result = nil

      # TODO: generalize this so don't have to specify all models
      if model == :steamer || model == :depthcharts || model == :zips
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
        unless empty_row?(row)
          # player = Player.new({ :draft_helper_id => @draft_helper, :league_id => @draft_helper.league, :user_id => @draft_helper.user, :is_drafted => false})
          player = @draft_helper.league.players.build({ :draft_helper_id => @draft_helper, :league_id => @draft_helper.league, :user_id => @draft_helper.user, :is_drafted => false})
          player.set_default_values

          player.process_data(row, model, type)
          players[player.name] = player if player.is_valid?
        end
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

    store_file_info(filename, players)
  end

  def empty_row?(row)
    is_empty = true

    row.each do |elem|
      if !elem.nil?
        is_empty = false
      end
    end

    is_empty
  end

  # TODO: if this fails when new file is added, hash value may still be there but may need to parse data -- may not exist in JSON
  def store_file_info(filename, players)
    @file_digests[filename] = Digest::MD5.file(filename)
  end

  def clean_player_lists()
    @batters.delete("BP-ONLY")
    @pitchers.delete("BP-ONLY")
  end
end
