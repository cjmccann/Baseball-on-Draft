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

      if props[:type] == :bat && !File.exist?(@batters_path)
        read_csv(filename, props[:model], props[:type])

      elsif props[:type] == :pit && !File.exist?(@pitchers_path)
        read_csv(filename, props[:model], props[:type])

      elsif @file_digests[filename] != Digest::MD5.file(filename).hexdigest
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
      hash[name] = { "position" => value.position, "player_type" => value.player_type, "stats" => value.stats }
    end

    begin
      JSON.pretty_generate(hash)
    rescue JSON::GeneratorError
      binding.pry
    end

    return JSON.pretty_generate(hash)
  end

  def convert_json_to_players(json)
    players = { }

    json.each do |name, value|
      player = @draft_helper.players.build({ :league_id => @draft_helper.league, :is_drafted => false, :name => name, 
                                               :position => value["position"], :player_type => value["type"], :user => @draft_helper.user })
      player.set_default_values

      player.process_data_from_json(value["stats"])
      player.player_type = value["player_type"]
      players[name] = player if player.is_valid?
    end

    return players
  end

  # TODO: make this collect into hash, write to json, and then read the json?
  # Would eliminate the need for player creation in two places.
  def read_csv(filename, model, type)
    if type == :bat
      players = @batters
    else
      players = @pitchers
    end

    csv = nil

    file = File.open(filename, "r")

    begin
      # work around for CSV::MalformedCSVError illegal quoting, but also skips header row
      csv = CSV.new(file, { skip_blanks: true })
      csv.gets
    rescue CSV::MalformedCSVError => e
      puts "CSV encountered illegal quoting error on line 1. Skipping and parsing rest of CSV."
    end

    csv.each do |row|
      result = nil
      name = nil

      # TODO: generalize this so don't have to specify all models
      if model == :steamer || model == :depthcharts || model == :zips
        result = players.select { |k, v| k == row[0] }
        name = row[0]
      elsif model == :pecota
        result = players.select do |k, v| 
          next if row[1].nil? || row[2].nil?

          bool_a = k.include?(row[1]) && k.include?(row[2])

          pecota_name = row[2] + ' ' + row[1]
          name = pecota_name
          bool_b = k.split(' ').reduce(true) { |prev, n| prev && pecota_name.include?(n) }
          
          (bool_a || bool_b)
        end
      end

      if result.empty?
        unless empty_row?(row)
          player = @draft_helper.players.build({ :league_id => @draft_helper.league, :is_drafted => false, :name => name, 
                                                 :player_type => type.to_s, :user => @draft_helper.user })

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

    store_file_info(filename)
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
  def store_file_info(filename)
    @file_digests[filename] = Digest::MD5.file(filename)
  end

  def clean_player_lists()
    @batters.delete("BP-ONLY")
    @pitchers.delete("BP-ONLY")
  end
end
