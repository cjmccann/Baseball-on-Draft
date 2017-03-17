if ActiveRecord::Base.connection.tables.include?('players') && !defined?(::Rake) && defined?(Rails::Server)
  Dir[File.join(Rails.root, 'lib', 'stats', '**', '*.rb')].each { |f| require_dependency f }

  parser = ProjectionParser.new
end
