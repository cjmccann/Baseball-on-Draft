require 'pry'
require 'json'

require_relative 'projection_parser'

class Model
  attr_accessor :parser

  def initialize(parser)
    @parser = parser
    compute_weighted_means(parser.batters)
    compute_weighted_means(parser.pitchers)
    binding.pry
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
end

parser = ProjectionParser.new()
Model.new(parser)
