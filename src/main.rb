require 'pry'
require 'json'
require 'optparse'

require_relative './rb/projection_parser'
require_relative './rb/data_manager'
require_relative './rb/team'

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
data_manager = DataManager.new(parser)
team = Team.new(data_manager)
team.inspect
binding.pry

