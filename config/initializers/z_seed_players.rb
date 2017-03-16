if ActiveRecord::Base.connection.tables.include?('players') && !defined?(::Rake)
  Dir[File.join(Rails.root, 'lib', 'stats', '**', '*.rb')].each { |f| require_dependency f }

  parser = ProjectionParser.new
end
