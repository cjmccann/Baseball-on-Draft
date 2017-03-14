class Player < ActiveRecord::Base
  attr_accessor :value, :type

  serialize :stats, Hash

  belongs_to :league
  belongs_to :user
  belongs_to :team

  validates_uniqueness_of :name, scope: :league_id

  def set_default_values
    @type = nil

    # TODO: initialize the stats Hash with all projection model names -- failed with zips
    self.stats = {
      :steamer => { },
      :depthcharts => { },
      :pecota => { },
      :zips => { }
    }
  end

  # TODO: is this needed? unused
  def compute_player_stddevs(averages)
    averages.each do |category, fields|
      self.stats[:means][category] - fields[:global_avg]

    end
  end

  # TODO: generalize this for new projection stats as well?
  def process_data_from_json(name, stats)
    self.name = name

    stats["steamer"].each do |category, val|
      self.stats[:steamer][category.to_sym] = val
    end

    stats["depthcharts"].each do |category, val|
      self.stats[:depthcharts][category.to_sym] = val 
    end

    stats["pecota"].each do |category, val|
      self.stats[:pecota][category.to_sym] = val
    end

    stats["zips"].each do |category, val|
      self.stats[:zips][category.to_sym] = val
    end 
  end

  def process_data(data, model, type)
    curr_model = ModelData.models[model][type]
    @type = type
    self.player_type = type.to_s

    if model == :steamer || model == :depthcharts
      self.name = data[curr_model[:name]]
    elsif @name == nil
      self.name = "BP-ONLY"
    end

    if model == :pecota && type == :bat
      self.position = data[curr_model[:pos]].strip
    end

    curr_model.each do |key, value|
      self.stats[model][key] = data[value]
    end
  end

  def assign_pitcher_pos()
    if self.stats[:means][:ip] > 80
      self.position = "SP"
    else
      self.position = "RP"
    end
  end

  def compute_quality_starts()
    # assumption: 4.5 era => 50% QS rate
    # compute this current player's QS rate based on this assumption
    
    qs_rate = (1 - ((0.5 * self.stats[:means][:era]) / 4.5))
    self.stats[:means][:qs] = self.stats[:means][:gs] * qs_rate
  end

  def is_valid?()
    min_pa = 200
    min_ip = 40

    has_min_pa = (self.stats[:steamer][:pa].to_f > min_pa || self.stats[:depthcharts][:pa].to_f > min_pa || self.stats[:pecota][:pa].to_f > min_pa )
    has_min_ip = (self.stats[:steamer][:ip].to_f > min_ip || self.stats[:depthcharts][:ip].to_f > min_ip || self.stats[:pecota][:ip].to_f > min_ip )

    return (has_min_pa || has_min_ip)
  end

  def compute_zscores(averages, stddevs)
    zscores = { }

    self.stats[:means].each do |category, value|
      zscores[category] = (value - averages[category][:global_avg]) / stddevs[category]
    end

    self.stats[:current_zscores] = zscores
  end

  def compute_percentile()
    percentiles = { }

    self.stats[:current_zscores].each do |category, value|
      if @type == :pit && (category == :era || category == :whip || category == :bbper9 || category == :l ||
                           category == :fip || category == :dra || category == :hr || category == :h )
        percentiles[category] = 100 - get_percentile(value)
      else
        percentiles[category] = get_percentile(value)
      end
    end

    self.stats[:current_percentiles] = percentiles
  end

  # TODO: refactor and combine with compute zscore
  def get_zscore_subset(averages, stddevs)
    zscores = { }

    averages.each do |category, obj|
      zscores[category] = (self.stats[:means][category] - obj[:global_avg]) / stddevs[category]
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
      sum += self.stats[:current_percentiles][category]
    end

    return sum
  end

  def is_drafted?
    self.is_drafted
  end

  def set_drafted
    @drafted = true
  end

  def matches_position?(pos)
    return false if pos.nil?
    return true if self.position == pos || pos == "UTIL"

    if pos == "CI"
      return true if self.position == "1B" || self.position == "3B"
    end

    if pos == "MI"
      return true if self.position == "2B" || self.position == "SS"
    end

    if pos == "OF"
      return true if self.position == "LF" || self.position == "CF" || self.position == "RF"
    end

    if pos == "P"
      return true if self.position == "SP" || self.position == "RP"
    end

    return false
  end

end
