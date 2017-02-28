require 'pry'
require 'json'
require 'optparse'

require_relative './rb/projection_parser'
require_relative './rb/global_stats'

class Model
  attr_accessor :parser, :batters, :pitchers, :global_stats

  def initialize(parser)
    @parser = parser
    @batters = parser.batters
    @pitchers = parser.pitchers
    @global_stats = GlobalStats.new()

    @global_stats.compute_weighted_means(@batters)
    @global_stats.compute_weighted_means(@pitchers)

    @global_stats.compute_average_weighted_means(:bat, @batters)
    @global_stats.compute_all_stddevs(:bat, batters)

    @global_stats.compute_average_weighted_means(:pit, @pitchers)
    @global_stats.compute_all_stddevs(:pit, @pitchers)

    @global_stats.compute_all_zscores(:bat, @batters)
    @global_stats.compute_all_zscores(:pit, @pitchers)

    @global_stats.compute_all_percentiles(:bat, @batters)
    @global_stats.compute_all_percentiles(:pit, @pitchers)

    binding.pry
  end

end

options = { }
OptionParser.new do |opts|
  opts.on('--forceProjectionProcessing') do 
    options[:forceProjectionProcessing] = true
  end

  opts.on('--forceAliasProcessing') do
    options[:forceAliasProcessing] = true
  end

  opts.on('--help') do
    puts opts
    exit
  end
end

parser = ProjectionParser.new(options)
Model.new(parser)
