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

  # after_create :init_dynamic_stats
  before_save :init_dynamic_stats, :set_default_values

  attr_accessor :dynamic_stats

  def update_cumulative_stats
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
  end

  private
  def init_dynamic_stats
    @dynamic_stats = { }
  end

  def ensure_dynamic_stats_for_player(player)
    if @dynamic_stats.nil?
      @dynamic_stats = { }
    end

    if @dynamic_stats[player.id].nil?
      @dynamic_stats[player.id] = { }
    end
  end

  def set_default_values
    compute_weighted_means(batters)
    compute_weighted_means(pitchers)

    compute_quality_starts(pitchers)

    update_cumulative_stats
    set_initial_zscores_and_percentiles
  end

  def batters
      @batters ||= self.draft_helper.batters
  end

  def pitchers
      @pitchers ||= self.draft_helper.pitchers
  end

  def all_players
      @all_players ||= self.draft_helper.all_players
  end

  def compute_weighted_means(players)
    players.each do |player|
      means = { }
      model_weights = ModelData.model_weights.clone

      model_weights.keys.each do |model|
        if player.static_stats[model].empty?
          weight_to_redist = model_weights[model]

          model_weights.delete(model)

          model_weights.keys.each do |model_b|
            model_weights[model_b] += (weight_to_redist / model_weights.length)
          end
        end
      end

      model_weights.keys.each do |model|
        set = player.static_stats[model]
        set.each do |category, stat_val|
          if category != :name && category != :firstname && category != :lastname && category != :pos
            if means[category].nil?
              means[category] = 0.0
            end

            means[category] += stat_val.to_f * model_weights[model]
          end
        end
      end

      ensure_dynamic_stats_for_player(player)
      @dynamic_stats[player.id][:means] = means
    end
  end
  
  def compute_average_weighted_means(averages, players)
    players.each do |player|
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(player)
      @dynamic_stats[player.id][:means].each do |category, value|
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
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(player)
      @dynamic_stats[player.id][:means].each do |category, value|
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
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(player)
      player.compute_zscores(self.averages[type], self.stddevs[type], @dynamic_stats[player.id])
    end
  end

  def compute_all_percentiles(players)
    players.each do |player|
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(player)
      player.compute_percentile(@dynamic_stats[player.id])
    end
  end

  def get_sorted_players_list_absolute_percentiles(pos = nil)
    player_values = { } 

    all_players.each do |player|
      unless is_drafted?(player)
        if pos.nil? || player.matches_position?(pos)
          player_values[player.id] = { :value => player.get_absolute_percentile_sum(self.target_stats, @dynamic_stats[player.id]), :player => player }
        end
      end
    end

    return player_values.sort_by { |name, obj| (-1) * obj[:value] }
  end

  def get_sorted_players_list_with_pos_adjustments(pos = nil)
    player_values = { } 

    all_players.each do |player|
      unless is_drafted?(player)
        if pos.nil? || player.matches_position?(pos)
          next if self.positional_adjustments[player.position].nil? 
          percentile_sum = player.get_absolute_percentile_sum(self.target_stats, @dynamic_stats[player.id])
          player_values[player.id] = { :value => percentile_sum * self.positional_adjustments[player.position], :player => player }
        end
      end
    end

    return player_values.sort_by { |name, obj|  (-1) * obj[:value] }
  end

  def get_sorted_players_list_with_pos_adjustments_plus_slots(pos = nil, team = nil)
    player_values = { }

    all_players.each do |player|
      unless is_drafted?(player)
        if pos.nil? || player.matches_position?(pos)
          next if self.positional_adjustments[player.position].nil?

          percentile_sum = player.get_absolute_percentile_sum(self.target_stats, @dynamic_stats[player.id])
          pos_adj = self.positional_adjustments[player.position]

          player_values[player.name] = { :value => (percentile_sum * pos_adj) * (1.0 + team.remaining_positional_impact(player.position)), 
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

  def compute_quality_starts(players)
    players.each do |player|
      ensure_dynamic_stats_for_player(player)
      player.compute_quality_starts(@dynamic_stats[player.id][:means])
    end
  end

  def set_initial_zscores_and_percentiles()
    batters.each do |player|
      ensure_dynamic_stats_for_player(player)
      @dynamic_stats[player.id][:initial_zscores] = @dynamic_stats[player.id][:current_zscores]
      @dynamic_stats[player.id][:initial_percentiles] = @dynamic_stats[player.id][:current_percentiles]
    end

    pitchers.each do |player|
      ensure_dynamic_stats_for_player(player)
      @dynamic_stats[player.id][:initial_zscores] = @dynamic_stats[player.id][:current_zscores]
      @dynamic_stats[player.id][:initial_percentiles] = @dynamic_stats[player.id][:current_percentiles]
    end
  end

  def is_drafted?(player)
    self.draft_helper.drafted_player_ids[player.id] ? true : false
  end
end
