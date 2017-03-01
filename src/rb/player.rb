class Player
  attr_accessor :name, :value, :stats, :position, :type

  def initialize()
    @name = nil
    @position = nil
    @type = nil

    @stats = {
      :steamer => { },
      :depthcharts => { },
      :pecota => { }
    }
  end

  def compute_player_stddevs(averages)
    averages.each do |category, fields|
      @stats[:means][category] - fields[:global_avg]

    end
  end

  def process_data_from_json(name, stats)
    @name = name
    @stats = {
      :steamer => { },
      :depthcharts => { },
      :pecota => { }
    }

    stats["steamer"].each do |category, stat|
      @stats[:steamer][category.to_sym] = stat
    end

    stats["depthcharts"].each do |category, stat|
      @stats[:depthcharts][category.to_sym] = stat
    end

    stats["pecota"].each do |category, stat|
      @stats[:pecota][category.to_sym] = stat
    end
  end

  def process_data(data, model, type)
    curr_model = ModelData.models[model][type]
    @type = type

    if model == :steamer || model == :depthcharts
      @name = data[curr_model[:name]]
    elsif @name == nil
      @name = "BP-ONLY"
    end

    if model == :pecota && type == :bat
      @position = data[curr_model[:pos]].strip
    end

    curr_model.each do |key, value|
      @stats[model][key] = data[value]
    end
  end

  def assign_pitcher_pos()
    if @stats[:means][:ip] > 80
      @position = "SP"
    else
      @position = "RP"
    end
  end

  def is_valid?()
    has_40_pa = (@stats[:steamer][:pa].to_f > 40 || @stats[:depthcharts][:pa].to_f > 40 || @stats[:pecota][:pa].to_f > 40)
    has_40_ip = (@stats[:steamer][:ip].to_f > 40 || @stats[:depthcharts][:ip].to_f > 40 || @stats[:pecota][:ip].to_f > 40)

    return (has_40_pa || has_40_ip)
  end

  def compute_zscore(averages, stddevs)
    zscores = { }

    @stats[:means].each do |category, value|
      zscores[category] = (value - averages[category][:global_avg]) / stddevs[category]
    end

    @stats[:zscores] = zscores
  end

  def compute_percentile()
    percentiles = { }

    @stats[:zscores].each do |category, value|
      if category == :era || category == :whip || category == :bbper9 || category == :fip || category == :dra
        percentiles[category] = 100 - get_percentile(value)
      else
        percentiles[category] = get_percentile(value)
      end

    end

    @stats[:percentiles] = percentiles
  end

  # http://stackoverflow.com/questions/31875909/z-score-to-probability-and-vice-verse-in-ruby
  def get_percentile(z)
    return 0 if z < -6.5
    return 1 if z > 6.5

    factk = 1
    sum = 0
    term = 1
    k = 0

    loopStop = Math.exp(-23)
    while term.abs > loopStop do
      term = 0.3989422804 * ((-1)**k) * (z**k) / (2*k+1) / (2**k) * (z**(k+1)) /factk
      sum += term
      k += 1
      factk *= k
    end

    sum += 0.5
    return sum * 100
    # 1-sum
  end
end
