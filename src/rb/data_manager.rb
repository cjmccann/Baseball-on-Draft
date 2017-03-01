class DataManager
  attr_accessor :parser, :batters, :pitchers, :averages

  def initialize(parser)
    @averages = { }
    @stddevs = { :bat => { }, :pit => { } }

    @parser = parser
    @batters = parser.batters
    @pitchers = parser.pitchers

    compute_weighted_means(@batters)
    compute_weighted_means(@pitchers)

    # uses mean IP to determine SP/RP
    assign_all_pitcher_pos(@pitchers)

    compute_average_weighted_means(:bat, @batters)
    compute_average_weighted_means(:pit, @pitchers)

    compute_all_stddevs(:bat, @batters)
    compute_all_stddevs(:pit, @pitchers)

    compute_all_zscores(:bat, @batters)
    compute_all_zscores(:pit, @pitchers)

    compute_all_percentiles(:bat, @batters)
    compute_all_percentiles(:pit, @pitchers)
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

  def compute_average_weighted_means(type, players)
    players.each do |name, player|
      player.stats[:means].each do |category, value|
        @averages[type] = { } if @averages[type].nil?
        @averages[type][category] = { } if @averages[type][category].nil?

        category = @averages[type][category]

        category[:values].nil? ? category[:values] = [value] : category[:values].push(value)
        category[:global_avg] = 0.0 if category[:global_avg].nil?
      end
    end

    @averages[type].each do |category, data|
      sum = 0.0

      data[:values].each do |value|
        sum += value.to_f
      end

      data[:global_avg] = sum / data[:values].length
    end
  end

  def compute_all_stddevs(type, players)
    square_dists = { }

    players.each do |name, player|
      player.stats[:means].each do |category, value|
        square_dist = (value - @averages[type][category][:global_avg]) ** 2
        square_dists[category].nil? ? square_dists[category] = [square_dist] : square_dists[category].push(square_dist)
      end
    end

    square_dists.each do |category, values|
      @stddevs[type][category] = Math.sqrt(values.reduce(0, :+) / values.length)
    end
  end

  def compute_all_zscores(type, players)
    players.each do |name, player|
      player.compute_zscore(@averages[type], @stddevs[type])
    end
  end

  def compute_all_percentiles(type, players)
    players.each do |name, player|
      player.compute_percentile()
    end
  end

  def assign_all_pitcher_pos(players)
    players.each do |name, player|
      player.assign_pitcher_pos()
    end
  end
end
