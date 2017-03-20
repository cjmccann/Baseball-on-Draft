class DataManager < ActiveRecord::Base
  belongs_to :draft_helper
  belongs_to :league
  belongs_to :user

  serialize :averages, Hash
  serialize :stddevs, Hash
  serialize :positional_adjustments, Hash

  serialize :means, Hash
  serialize :current_zscores, Hash
  serialize :current_percentiles, Hash
  serialize :initial_zscores, Hash
  serialize :initial_percentiles, Hash

  # after_create :init_dynamic_stats
  # before_save :set_default_values

  attr_accessor :dynamic_stats_init

  def set_initial_values
    @dynamic_stats_init = true

    self.means = { }
    self.initial_zscores= { }
    self.initial_percentiles = { }
    self.current_zscores = { }
    self.current_percentiles = { }

    compute_weighted_means(batters)
    compute_weighted_means(pitchers)

    compute_quality_starts(pitchers)

    update_cumulative_stats
    set_initial_zscores_and_percentiles

    @dynamic_stats_init = false

    update_cumulative_stats
  end

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

  def get_sorted_players_list(pos = nil)
      player_values = [ ]
      minmax = { :min => 0, :max => 0 }

      all_players.each do |player|
        unless is_drafted?(player)
          if pos.nil? || player.matches_position?(pos)
            deltas_obj = self.league.my_team.get_target_percentile_deltas_with_new_player(player, minmax)

            player_values.push({ :value => deltas_obj[:deltas_magnitude].round(3), :id => player.id,
                                         :categories => deltas_obj[:deltas][player.player_type.to_sym],
                                         :means => self.means[player.id],
                                         :name => player.name, :player_type => player.player_type, :position => player.position })
          end
        end
      end

      return { :players => player_values.sort_by! { |obj| (-1) * obj[:value] }, :minmax => minmax }
  end 

  def get_sorted_players_list_absolute_percentiles(pos = nil)
    player_values = [ ]
    minmax = { :min => 0, :max => 0 }

    all_players.each do |player|
      unless is_drafted?(player)
        if pos.nil? || player.matches_position?(pos)
          percentiles_obj = get_absolute_percentile_sum(player, self.current_percentiles[player.id], minmax)

          value = percentiles_obj[:sum].round(3)

          player_values.push({ :value => value, :id => player.id, :categories => percentiles_obj[:percentiles][player.player_type],
                               :means => self.means[player.id], :name => player.name, :player_type => player.player_type, 
                               :position => player.position })
        end
      end
    end

    return { :players => player_values.sort_by! { |obj| (-1) * obj[:value] }, :minmax => minmax }
  end

  def get_sorted_players_list_with_pos_adjustments(pos = nil)
    player_values = [ ]
    minmax = { :min => 0, :max => 0 }

    all_players.each do |player|
      unless is_drafted?(player)
        if pos.nil? || player.matches_position?(pos)
          next if self.positional_adjustments[player.position].nil? 
          percentile_sum = get_absolute_percentile_sum(player, self.current_percentiles[player.id], minmax)

          value = (percentile_sum[:sum] * self.positional_adjustments[player.position]).round(3)

          player_values.push({ :value => value, :categories => percentile_sum[:percentiles][player.player_type], :id => player.id,
                               :means => self.means[player.id], :name => player.name, :player_type => player.player_type, 
                               :position => player.position })
        end
      end
    end

    return  { :players => player_values.sort_by! { |obj|  (-1) * obj[:value] }, :minmax => minmax }
  end

  def get_sorted_players_list_with_pos_adjustments_plus_slots(pos = nil, team = nil)
    player_values = [ ]
    minxmax = { :min => 0, :max => 0 }

    all_players.each do |player|
      unless is_drafted?(player)
        if pos.nil? || player.matches_position?(pos)
          next if self.positional_adjustments[player.position].nil?

          percentile_sum = get_absolute_percentile_sum(player, self.current_percentiles[player.id], minmax)
          pos_adj = self.positional_adjustments[player.position]

          value = ((percentile_sum[:sum] * pos_adj) * (1.0 + self.league.my_team.remaining_positional_impact(player.position))).round(3)

          player_values.push({ :value => value, :categories => percentile_sum[:percentiles][player.player_type], :id => player.id, 
                               :means => self.means[player.id], :name => player.name, :player_type => player.player_type, 
                               :position => player.position })
        end
      end 
    end

    return { :players => player_values.sort_by { |obj| (-1) * obj[:value] }, :minmax => minmax }
  end

  def batter_slots
    self.league.setting_manager.get_positions[:bat]
  end

  def pitcher_slots
    self.league.setting_manager.get_positions[:pit]
  end

  def target_stats
    self.league.setting_manager.get_stats
  end

  # http://stackoverflow.com/questions/31875909/z-score-to-probability-and-vice-verse-in-ruby
  def get_percentile(z)
    return 0 if z < -6.5
    return 100 if z > 6.5

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
    return (sum * 100).round(3)
    # 1-sum
  end

  private
  def ensure_dynamic_stats_for_player(field, player)
    if self[field].nil?
      self[field] = { }
    end

    if self[field][player.id].nil?
      self[field][player.id] = { }
    end
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

            model_weight_with_exceptions = get_model_weight_with_category_exceptions(category, model_weights, model)
            means[category] += (stat_val.to_f * model_weight_with_exceptions).round(3)
          end
        end
      end

      ensure_dynamic_stats_for_player(:means, player)
      self.means[player.id] = means
    end
  end

  def get_model_weight_with_category_exceptions(category, model_weights, model)
    # to handle models that DON'T have a specific category
    # e.g. zips does not include sv, so we re-distribute save-weight among other 3
    
    # zips does not have sv
    if category == :sv && model != :zips

      # sometimes, zips won't have included this player and weights have already been redistributed
      if !(model_weights[:zips].nil?)
        return model_weights[model] + (model_weights[:zips] / 3)
       end
    end

    model_weights[model]
  end
  
  def compute_average_weighted_means(averages, players)
    values = { }

    players.each do |player|
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(:means, player)
      self.means[player.id].each do |category, value|
        values[category] = [ ] if values[category].nil?

        # for pitching, in avg weighted mean don't include :sv for starters, :qs for relievers
        if player.player_type == "pit"
          if player.position == "SP" && category == :sv
            next
          elsif player.position == "RP" && (category == :qs || category == :w || category == :l || category == :gs)
            next
          end
        end

        values[category].push(value)
      end
    end

    values.each do |category, data|
      sum = 0.0

      data.each do |value|
        sum += value.to_f
      end

      averages[category] = (sum / data.length).round(3)
    end
  end

  def compute_all_stddevs(stddevs, averages, players)
    square_dists = { }

    players.each do |player|
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(:means, player)
      self.means[player.id].each do |category, value|
        # for pitching, in avg weighted mean don't include :sv for starters, :qs for relievers
        if player.player_type == "pit"
          if player.position == "SP" && category == :sv
            next
          elsif player.position == "RP" && (category == :qs || category == :w || category == :l || category == :gs)
            next
          end
        end

        square_dist = (value - averages[category]) ** 2
        square_dists[category].nil? ? square_dists[category] = [square_dist] : square_dists[category].push(square_dist)
      end
    end

    square_dists.each do |category, values|
      stddevs[category] = Math.sqrt(values.reduce(0, :+) / values.length).round(3)
    end
  end

  def compute_all_zscores(type, players)
    players.each do |player|
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(:current_zscores, player)
      self.current_zscores[player.id] = compute_zscores(self.averages[type], self.stddevs[type], self.means[player.id], player)
    end
  end

  def compute_zscores(averages, stddevs, means, player)
    zscores = { }

    means.each do |category, value|
      # for pitching, in avg weighted mean don't include :sv for starters, :qs for relievers
      if player.player_type == "pit"
        if player.position == "SP" && category == :sv
          next
        elsif player.position == "RP" && (category == :qs || category == :w || category == :l || category == :gs)
          next
        end
      end

      zscores[category] = ((value - averages[category]) / stddevs[category]).round(3)
    end

    zscores
  end

  def compute_all_percentiles(players)
    players.each do |player|
      next if is_drafted?(player)

      ensure_dynamic_stats_for_player(:current_percentiles, player)
      self.current_percentiles[player.id] = compute_percentile(player, self.current_zscores[player.id])
    end
  end

  def compute_percentile(player, zscores)
    percentiles = { }

    zscores.each do |category, value|
      # for pitching, in avg weighted mean don't include :sv for starters, :qs for relievers
      if player.player_type == "pit"
        if player.position == "SP" && category == :sv
          next
        elsif player.position == "RP" && (category == :qs || category == :w || category == :l || category == :gs)
          next
        end
      end

      if player.player_type.to_sym == :pit && (category == :era || category == :whip || category == :bbper9 || category == :l ||
                           category == :fip || category == :dra || category == :hr || category == :h )
        percentiles[category] = 100 - get_percentile(value)
      else
        percentiles[category] = get_percentile(value)
      end
    end

    percentiles
  end


  def set_positional_adjustments()
    volatilities = { :bat => { }, :pit => { } }
    subset_size = 10

    batter_slots.each do |pos, _|
      # TODO: Excluding RF/LF/CF due to league settings, only need OF slots
      next if pos == "CI" || pos == "MI" || pos == "UTIL" || pos == "RF" || pos == "LF" || pos == "CF"
      volatilities[:bat][pos] = get_volatility_for_position(pos, subset_size)
    end

    pitcher_slots.each do |pos, _|
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
    sorted_players_subset = get_sorted_players_list_absolute_percentiles(pos)[:players].slice(0, n)
    players = [ ]

    sorted_players_subset.each do |player|
      players.push(Player.find(player[:id]))
    end

    if !players.empty?
      type = players[0].player_type.to_sym
    else
      # TODO: Do this better, get type in some other way.
      puts "Players list is empty when getting variance."
    end

    get_volatility_for_players(players, target_stats[type])
  end

  def get_volatility_for_players(players, target_stats)
    averages = { }
    stddevs = { }

    compute_average_weighted_means(averages, players)
    compute_all_stddevs(stddevs, averages, players)

    target_averages = { }
    target_stddevs = { } 

    target_stats.each do |category|
      next if averages[category].nil? || averages[category].nan?
      target_averages[category] = averages[category]
      target_stddevs[category] = stddevs[category]
    end

    positional_volatility = 0.0

    target_averages.each do |category, value|
      #if stddev for category is 0, the category is always 0 with no variability, and adds no volatility
      # next if target_stddevs[category] == 0.0

      # TODO: understand what to do when STDDEV for category is 0 -- gs for RP
      if target_stddevs[category] == 0.0
        positional_volatility += 1.0
      else
        positional_volatility += (target_stddevs[category] / value)
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
      ensure_dynamic_stats_for_player(:means, player)
      player.compute_quality_starts(self.means[player.id])
    end
  end

  def get_absolute_percentile_sum(player, current_percentiles, minmax)
    vals = { :sum => 0.0, :percentiles => { 'bat' => { }, 'pit' => { } } }

    target_stats[player.player_type.to_sym].each do |category|
      if current_percentiles[category].nil?
        vals[:sum] += 0
        vals[:percentiles][player.player_type][category] = 0.0
      else 
        vals[:sum] += current_percentiles[category]
        vals[:percentiles][player.player_type][category] = current_percentiles[category].round(3)

        if vals[:percentiles][player.player_type][category] < minmax[:min]
          minmax[:min] = vals[:percentiles][player.player_type][category]
        elsif vals[:percentiles][player.player_type][category] > minmax[:max]
          minmax[:max] = vals[:percentiles][player.player_type][category]
        end
      end
    end

    return vals
  end

  def set_initial_zscores_and_percentiles()
    batters.each do |player|
      ensure_dynamic_stats_for_player(:initial_zscores, player)
      ensure_dynamic_stats_for_player(:current_zscores, player)
      ensure_dynamic_stats_for_player(:initial_percentiles, player)
      ensure_dynamic_stats_for_player(:current_percentiles, player)

      self.initial_zscores[player.id] = self.current_zscores[player.id]
      self.initial_percentiles[player.id] = self.current_percentiles[player.id]
    end

    pitchers.each do |player|
      ensure_dynamic_stats_for_player(:initial_zscores, player)
      ensure_dynamic_stats_for_player(:current_zscores, player)
      ensure_dynamic_stats_for_player(:initial_percentiles, player)
      ensure_dynamic_stats_for_player(:current_percentiles, player)

      self.initial_zscores[player.id] = self.current_zscores[player.id]
      self.initial_percentiles[player.id] = self.current_percentiles[player.id]
    end
  end

  def is_drafted?(player)
    if @dynamic_stats_init
      return false
    else 
      self.draft_helper.drafted_player_ids[player.id] ? true : false
    end
  end


end
