class DataManager < ActiveRecord::Base
  belongs_to :draft_helper
  belongs_to :league
  belongs_to :user

  serialize :averages, Hash
  serialize :stddevs, Hash
  serialize :positional_adjustments, Hash
  serialize :target_stats, Hash
  serialize :batter_slots, Hash
  serialize :pitcher_slots, Hash

  before_save :set_default_values

  attr_accessor :batters, :pitchers

  def update_cumulative_stats(do_save)
    self.averages = { :bat => { }, :pit => { } }
    self.stddevs = { :bat => { }, :pit => { } }
    self.positional_adjustments = { }

    compute_average_weighted_means(self.averages[:bat], batters)
    compute_average_weighted_means(self.averages[:pit], pitchers)

    compute_all_stddevs(self.stddevs[:bat], self.averages[:bat], batters)
    compute_all_stddevs(self.stddevs[:pit], self.averages[:pit], pitchers)

    compute_all_zscores(:bat, batters)
    compute_all_zscores(:pit, pitchers)

    compute_all_percentiles(batters)
    compute_all_percentiles(pitchers)
     
    set_positional_adjustments()
    save_all_players() if do_save
  end

  private
  def set_default_values
    compute_weighted_means(batters)
    compute_weighted_means(pitchers)

    # uses mean IP to determine SP/RP
    assign_all_pitcher_pos(pitchers)
    compute_quality_starts(pitchers)

    update_cumulative_stats(false)
    set_initial_zscores_and_percentiles
    save_all_players
  end

  def batters
    if @batters
      @batters
    else 
      self.draft_helper.batters
    end
  end

  def pitchers
    if @pitchers
      @pitchers
    else
      self.draft_helper.pitchers
    end
  end

  def all_players
    if @batters && @pitchers
      @batters.concat(@pitchers)
    else
      self.draft_helper.all_players
    end
  end

  def compute_weighted_means(players)
    players.each do |player|
      means = { }
      model_weights = ModelData.model_weights.clone

      model_weights.keys.each do |model|
        if player.stats[model].empty?
          weight_to_redist = model_weights[model]

          model_weights.delete(model)

          model_weights.keys.each do |model_b|
            model_weights[model_b] += (weight_to_redist / model_weights.length)
          end
        end
      end

      model_weights.keys.each do |model|
        set = player.stats[model]
        set.each do |category, stat_val|
          if category != :name && category != :firstname && category != :lastname && category != :pos
            if means[category].nil?
              means[category] = 0.0
            end

            means[category] += stat_val.to_f * model_weights[model]
          end
        end
      end

      player.stats[:means] = means
      player.stats_will_change!
    end
  end
  
  def compute_average_weighted_means(averages, players)
    players.each do |player|
      next if player.is_drafted?

      player.stats[:means].each do |category, value|
        averages = { } if averages.nil?
        averages[category] = { } if averages[category].nil?

        category = averages[category]

        category[:values].nil? ? category[:values] = [value] : category[:values].push(value)
        category[:global_avg] = 0.0 if category[:global_avg].nil?
      end
    end

    averages.each do |category, data|
      sum = 0.0

      data[:values].each do |value|
        sum += value.to_f
      end


      data[:global_avg] = sum / data[:values].length
    end
  end

  def compute_all_stddevs(stddevs, averages, players)
    square_dists = { }

    players.each do |player|
      next if player.is_drafted?

      player.stats[:means].each do |category, value|
        square_dist = (value - averages[category][:global_avg]) ** 2
        square_dists[category].nil? ? square_dists[category] = [square_dist] : square_dists[category].push(square_dist)
      end
    end

    square_dists.each do |category, values|
      stddevs[category] = Math.sqrt(values.reduce(0, :+) / values.length)
    end
  end

  def compute_all_zscores(type, players)
    players.each do |player|
      next if player.is_drafted?

      player.compute_zscores(self.averages[type], self.stddevs[type])
    end
  end

  def compute_all_percentiles(players)
    players.each do |player|
      next if player.is_drafted?

      player.compute_percentile()
    end
  end

  def get_sorted_players_list_absolute_percentiles(pos = nil)
    player_values = { } 

    all_players.each do |player|
      unless player.is_drafted?
        if pos.nil? || player.matches_position?(pos)
          player_values[player.name] = { :value => player.get_absolute_percentile_sum(self.target_stats), :player => player }
        end
      end
    end

    return player_values.sort_by { |name, obj| (-1) * obj[:value] }
  end

  def get_sorted_players_list_with_pos_adjustments(pos = nil)
    player_values = { } 

    all_players.each do |player|
      unless player.is_drafted?
        if pos.nil? || player.matches_position?(pos)
          next if self.positional_adjustments[player.position].nil? 
          player_values[player.name] = { :value => player.get_absolute_percentile_sum(self.target_stats) * self.positional_adjustments[player.position], 
                                  :player => player }
        end
      end
    end

    return player_values.sort_by { |name, obj|  (-1) * obj[:value] }
  end

  def get_sorted_players_list_with_pos_adjustments_plus_slots(pos = nil, team = nil)
    player_values = { }

    all_players.each do |player|
      unless player.is_drafted?
        if pos.nil? || player.matches_position?(pos)
          next if self.positional_adjustments[player.position].nil?

          player_values[player.name] = { :value => (player.get_absolute_percentile_sum(self.target_stats) * self.positional_adjustments[player.position]) * (1.0 + team.remaining_positional_impact(player.position)),
                                  :players => player }
        end
      end 
    end

    return player_values.sort_by { |name, obj| (-1) * obj[:value] }
  end


  def set_positional_adjustments()
    volatilities = { :bat => { }, :pit => { } }
    subset_size = 10

    self.batter_slots.each do |pos, _|
      # TODO: Excluding RF/LF/CF due to league settings, only need OF slots
      next if pos == "CI" || pos == "MI" || pos == "UTIL" || pos == "RF" || pos == "LF" || pos == "CF"
      volatilities[:bat][pos] = get_volatility_for_position(pos, subset_size)
    end

    self.pitcher_slots.each do |pos, _|
      next if pos == "P"
      volatilities[:pit][pos] = get_volatility_for_position(pos, subset_size)
    end

    avg_batter_volatility = volatilities[:bat].values.reduce(0, :+) / volatilities[:bat].length
    avg_pitcher_volatility = volatilities[:pit].values.reduce(0, :+) / volatilities[:pit].length

    volatilities[:bat].each do |pos, value|
      self.positional_adjustments[pos] = (value / avg_batter_volatility)
    end

    volatilities[:pit].each do |pos, value|
      self.positional_adjustments[pos] = (value / avg_pitcher_volatility)
    end
  end

  def get_volatility_for_position(pos, n)
    sorted_players_subset = get_sorted_players_list_absolute_percentiles(pos).slice(0, n)
    players = { }

    sorted_players_subset.each do |elem|
      players[elem[0]] = elem[1][:player]
    end

    if !players.empty?
      type = players.values[0].player_type.to_sym
    else
      # TODO: Do this better, get type in some other way.
      puts "Players list is empty when getting variance."
    end

    get_volatility_for_players(players.values, self.target_stats[type])
  end

  def get_volatility_for_players(players, target_stats)
    averages = { }
    stddevs = { }

    compute_average_weighted_means(averages, players)
    compute_all_stddevs(stddevs, averages, players)

    target_averages = { }
    target_stddevs = { } 

    target_stats.each do |category|
      target_averages[category] = averages[category]
      target_stddevs[category] = stddevs[category]
    end

    positional_volatility = 0.0

    target_averages.each do |category, obj|
      #if stddev for category is 0, the category is always 0 with no variability, and adds no volatility
      # next if target_stddevs[category] == 0.0

      # TODO: understand what to do when STDDEV for category is 0 -- gs for RP
      if target_stddevs[category] == 0.0
        positional_volatility += 1.0
      else
        positional_volatility += (target_stddevs[category] / obj[:global_avg])
      end 
    end

    positional_volatility = positional_volatility / target_averages.length

    return positional_volatility
    #players.each do |name, player|
      # zscores = player.get_zscore_subset(target_averages, target_stddevs)
      # percentiles = player.get_percentile_subset(zscores)
    #end
  end


  def assign_all_pitcher_pos(players)
    players.each do |player|
      player.assign_pitcher_pos()
    end
  end

  def compute_quality_starts(players)
    players.each do |player|
      player.compute_quality_starts()
    end
  end

  def set_initial_zscores_and_percentiles()
    batters.each do |player|
      player.stats[:initial_zscores] = player.stats[:current_zscores]
      player.stats[:initial_percentiles] = player.stats[:current_percentiles]
    end

    pitchers.each do |player|
      player.stats[:initial_zscores] = player.stats[:current_zscores]
      player.stats[:initial_percentiles] = player.stats[:current_percentiles]
    end
  end

  def save_all_players
    all_players.each do |player|
      player.save
    end
  end
end
