class GlobalStats
  attr_accessor :averages

  def initialize( )
    @averages = { }
    @stddevs = { :bat => { }, :pit => { } }
  end

  def compute_weighted_means(players)
    players.each do |name, player|
      means = { }

      player.stats.each do |model, set|
        set.each do |category, stat|
          if category != :name && category != :firstname && category != :lastname && category != :pos
            if means[category].nil?
              means[category] = 0.0
            end

            means[category] += stat.to_f * ModelData.model_weights[model]
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
end
