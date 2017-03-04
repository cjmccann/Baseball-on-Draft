class DataManager
  attr_accessor :parser, :batters, :pitchers, :averages, :stddevs

  def initialize(parser)
    @averages = { :bat => { }, :pit => { } }
    @stddevs = { :bat => { }, :pit => { } }

    @parser = parser
    @batters = parser.batters
    @pitchers = parser.pitchers

    compute_weighted_means(@batters)
    compute_weighted_means(@pitchers)

    # uses mean IP to determine SP/RP
    assign_all_pitcher_pos(@pitchers)

    compute_average_weighted_means(@averages[:bat], @batters)
    compute_average_weighted_means(@averages[:pit], @pitchers)

    compute_all_stddevs(@stddevs[:bat], @averages[:bat], @batters)
    compute_all_stddevs(@stddevs[:pit], @averages[:pit], @pitchers)

    compute_all_zscores(:bat, @batters)
    compute_all_zscores(:pit, @pitchers)

    compute_all_percentiles(@batters)
    compute_all_percentiles(@pitchers)

    set_initial_zscores_and_percentiles()
  end

  def update_cumulative_stats
    @averages = { }
    @stddevs = { :bat => { }, :pit => { } }

    compute_average_weighted_means(@averages[:bat], @batters)
    compute_average_weighted_means(@averages[:pit], @pitchers)

    compute_all_stddevs(@stddevs[:bat], @averages[:bat], @batters)
    compute_all_stddevs(@stddevs[:pit], @averages[:pit], @pitchers)

    compute_all_zscores(:bat, @batters)
    compute_all_zscores(:pit, @pitchers)

    compute_all_percentiles(@batters)
    compute_all_percentiles(@pitchers)
  end

  def compute_weighted_means(players)
    players.each do |name, player|
      means = { }
      model_weights = ModelData.model_weights.clone

      player.stats.each do |model, set|
        if set.empty?
          weight_to_redist = model_weights[model]

          model_weights.delete(model)

          model_weights.keys.each do |model_b|
            model_weights[model_b] += (weight_to_redist / model_weights.length)
          end
        end
      end

      player.stats.each do |model, set|
        set.each do |category, stat|
          if category != :name && category != :firstname && category != :lastname && category != :pos
            if means[category].nil?
              means[category] = 0.0
            end

            means[category] += stat.to_f * model_weights[model]
          end
        end
      end

      player.stats[:means] = means
    end
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

  def compute_average_weighted_means(averages, players)
    players.each do |name, player|
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

    players.each do |name, player|
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
    players.each do |name, player|
      next if player.is_drafted?

      player.compute_zscores(@averages[type], @stddevs[type])
    end
  end

  def compute_all_percentiles(players)
    players.each do |name, player|
      next if player.is_drafted?

      player.compute_percentile()
    end
  end

  def assign_all_pitcher_pos(players)
    players.each do |name, player|
      player.assign_pitcher_pos()
    end
  end

  def set_initial_zscores_and_percentiles()
    @batters.each do |name, player|
      player.stats[:initial_zscores] = player.stats[:current_zscores]
      player.stats[:initial_percentiles] = player.stats[:current_percentiles]
    end

    @pitchers.each do |name, player|
      player.stats[:initial_zscores] = player.stats[:current_zscores]
      player.stats[:initial_percentiles] = player.stats[:current_percentiles]
    end
  end
end
