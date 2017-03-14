class Player < ActiveRecord::Base
  attr_accessor :name, :value, :stats, :position, :type

  before_create :set_default_values

  def set_default_values
    @name = nil
    @position = nil
    @type = nil
    @drafted = false

    # TODO: initialize the stats Hash with all projection model names -- failed with zips
    @stats = {
      :steamer => { },
      :depthcharts => { },
      :pecota => { },
      :zips => { }
    }
  end

  # TODO: is this needed? unused
  def compute_player_stddevs(averages)
    averages.each do |category, fields|
      @stats[:means][category] - fields[:global_avg]

    end
  end

  # TODO: generalize this for new projection stats as well?
  def process_data_from_json(name, stats)
    @name = name

    stats["steamer"].each do |category, stat|
      @stats[:steamer][category.to_sym] = stat
    end

    stats["depthcharts"].each do |category, stat|
      @stats[:depthcharts][category.to_sym] = stat
    end

    stats["pecota"].each do |category, stat|
      @stats[:pecota][category.to_sym] = stat
    end

    stats["zips"].each do |category, stat|
      @stats[:zips][category.to_sym] = stat
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

  def compute_quality_starts()
    # assumption: 4.5 era => 50% QS rate
    # compute this current player's QS rate based on this assumption
    
    qs_rate = (1 - ((0.5 * @stats[:means][:era]) / 4.5))
    @stats[:means][:qs] = @stats[:means][:gs] * qs_rate
  end

  def is_valid?()
    min_pa = 200
    min_ip = 40

    has_min_pa = (@stats[:steamer][:pa].to_f > min_pa || @stats[:depthcharts][:pa].to_f > min_pa || @stats[:pecota][:pa].to_f > min_pa )
    has_min_ip = (@stats[:steamer][:ip].to_f > min_ip || @stats[:depthcharts][:ip].to_f > min_ip || @stats[:pecota][:ip].to_f > min_ip )

    return (has_min_pa || has_min_ip)
  end

  def compute_zscores(averages, stddevs)
    zscores = { }

    @stats[:means].each do |category, value|
      zscores[category] = (value - averages[category][:global_avg]) / stddevs[category]
    end

    @stats[:current_zscores] = zscores
  end

  def compute_percentile()
    percentiles = { }

    @stats[:current_zscores].each do |category, value|
      if @type == :pit && (category == :era || category == :whip || category == :bbper9 || category == :l ||
                           category == :fip || category == :dra || category == :hr || category == :h )
        percentiles[category] = 100 - get_percentile(value)
      else
        percentiles[category] = get_percentile(value)
      end
    end

    @stats[:current_percentiles] = percentiles
  end

  # TODO: refactor and combine with compute zscore
  def get_zscore_subset(averages, stddevs)
    zscores = { }

    averages.each do |category, obj|
      zscores[category] = (@stats[:means][category] - obj[:global_avg]) / stddevs[category]
    end

    return zscores
  end

  def get_percentile_subset(zscores)
    percentiles = { }

    zscores.each do |category, value|
      if @type == :pit && (category == :era || category == :whip || category == :bbper9 || 
                           category == :fip || category == :dra || category == :hr)
        percentiles[category] = 100 - get_percentile(value)
      else
        percentiles[category] = get_percentile(value)
      end
    end

    return percentiles
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

  def get_absolute_percentile_sum(target_stats)
    sum = 0.0

    target_stats[@type].each do |category|
      sum += @stats[:current_percentiles][category]
    end

    return sum
  end

  def is_drafted?
    @drafted
  end

  def set_drafted
    @drafted = true
  end

  def matches_position?(pos)
    return false if pos.nil?
    return true if @position == pos || pos == "UTIL"

    if pos == "CI"
      return true if @position == "1B" || @position == "3B"
    end

    if pos == "MI"
      return true if @position == "2B" || @position == "SS"
    end

    if pos == "OF"
      return true if @position == "LF" || @position == "CF" || @position == "RF"
    end

    if pos == "P"
      return true if @position == "SP" || @position == "RP"
    end

    return false
  end

end
