require 'pry'
require 'json'
require 'optparse'

require_relative './rb/controller'

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

Controller.new(options).main_loop()

