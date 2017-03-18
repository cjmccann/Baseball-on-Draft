class Player < ActiveRecord::Base
  serialize :static_stats, Hash

  validates_uniqueness_of :name, scope: :player_type

  def set_default_values
    # TODO: initialize the stats Hash with all projection model names -- failed with zips
    self.static_stats = {
      :steamer => { },
      :depthcharts => { },
      :pecota => { },
      :zips => { }
    }
  end

  # TODO: is this needed? unused
  def compute_player_stddevs(averages)
    averages.each do |category, fields|
      self.static_stats[:means][category] - fields[:global_avg]

    end
  end

  # TODO: generalize this for new projection stats as well?
  def process_data_from_json(stats)
    stats["steamer"].each do |category, val|
      self.static_stats[:steamer][category.to_sym] = val
    end

    stats["depthcharts"].each do |category, val|
      self.static_stats[:depthcharts][category.to_sym] = val 
    end

    stats["pecota"].each do |category, val|
      self.static_stats[:pecota][category.to_sym] = val
    end

    stats["zips"].each do |category, val|
      self.static_stats[:zips][category.to_sym] = val
    end 
  end

  def process_data(data, model, type)
    curr_model = ModelData.models[model][type]
    
    self.player_type = type.to_s

    if self.name.nil? && (model == :steamer || model == :depthcharts)
      self.name = data[curr_model[:name]]
    elsif self.name.nil?
      self.name = "BP-ONLY"
    end

    if model == :pecota && type == :bat
      self.position = data[curr_model[:pos]].strip
    end

    curr_model.each do |key, value|
      if key == :name || key == :firstname || key == :lastname
        self.static_stats[model][key] = data[value]
      else
        self.static_stats[model][key] = data[value].to_f
      end
    end
  end

  def assign_pitcher_pos()
    sp_inning_minimum = 80
    save_minimum = 2

    meets_inning_minimum = ((self.static_stats[:steamer][:ip] && self.static_stats[:steamer][:ip] > sp_inning_minimum ) || 
       (self.static_stats[:depthcharts][:ip] && self.static_stats[:depthcharts][:ip] > sp_inning_minimum ) ||
       (self.static_stats[:zips][:ip] && self.static_stats[:zips][:ip] > sp_inning_minimum ) ||
       (self.static_stats[:pecota][:ip] && self.static_stats[:pecota][:ip] > sp_inning_minimum ))

    above_save_minimum = ((self.static_stats[:steamer][:sv] && self.static_stats[:steamer][:sv] > save_minimum) ||
       (self.static_stats[:depthcharts][:sv] && self.static_stats[:depthcharts][:sv] > save_minimum) ||
       (self.static_stats[:pecota][:sv] && self.static_stats[:pecota][:sv] > save_minimum))

    if (meets_inning_minimum && !above_save_minimum)
      self.position = "SP"
    else
      self.position = "RP"
    end
  end

  def compute_quality_starts(means)
    # assumption: 4.5 era => 50% QS rate
    # compute this current player's QS rate based on this assumption
    
    qs_rate = (1 - ((0.5 * means[:era]) / 4.5))
    means[:qs] = means[:gs] * qs_rate
  end

  def is_valid?()
    min_pa = 400
    min_ip = 50

    has_min_pa = (self.static_stats[:steamer][:pa].to_f > min_pa || self.static_stats[:depthcharts][:pa].to_f > min_pa || 
                  self.static_stats[:pecota][:pa].to_f > min_pa || self.static_stats[:zips][:pa].to_f > min_pa)
    has_min_ip = (self.static_stats[:steamer][:ip].to_f > min_ip || self.static_stats[:depthcharts][:ip].to_f > min_ip || 
                  self.static_stats[:pecota][:ip].to_f > min_ip || self.static_stats[:zips][:ip].to_f > min_ip)

    return (has_min_pa || has_min_ip)
  end


  # TODO: refactor and combine with compute zscore
  def get_zscore_subset(averages, stddevs, dynamic_stats)
    zscores = { }

    averages.each do |category, obj|
      zscores[category] = (dynamic_stats[:means][category] - obj[:global_avg]) / stddevs[category]
    end

    return zscores
  end

  def get_percentile_subset(zscores)
    percentiles = { }

    zscores.each do |category, value|
      if self.player_type.to_sym == :pit && (category == :era || category == :whip || category == :bbper9 || 
                           category == :fip || category == :dra || category == :hr)
        percentiles[category] = 100 - get_percentile(value)
      else
        percentiles[category] = get_percentile(value)
      end
    end

    return percentiles
  end


  def get_absolute_percentile_sum(target_stats, dynamic_stats)
    sum = 0.0

    target_stats[self.player_type.to_sym].each do |category|
      if dynamic_stats[:current_percentiles][category].nil?
        sum += 0
      else 
        sum += dynamic_stats[:current_percentiles][category]
      end
    end

    return sum
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
