require 'set'
require 'csv'

class Aliases 
  # TODO: Convert all this to JSON instead of csv. csv bad.
  @@aliases = { }
  @@aliases_filepath = File.expand_path(File.dirname(__FILE__) + "/../data/aliases.csv")

  def self.aliases
    @@aliases
  end

  def self.load_aliases()
    CSV.foreach(@@aliases_filepath) do |row|
        processing_aliases = true

        row.each_index do |i|
          if i == 0
            init_entry(row[i])
            next
          end

          if row[i] == "EXCLUSIONS"
            processing_aliases = false
            next
          end

          if processing_aliases
            add_alias(row[0], row[i])
          else
            add_exclusion(row[0], row[i])
          end
        end
    end
  end

  def self.init_entry(name)
    @@aliases[name] = { :aliases => Set.new(), :exclusions => Set.new() }
  end
    
  def self.add_alias(existing_name, new_name)
    init_entry(existing_name) if @@aliases[existing_name].nil?
    @@aliases[existing_name][:aliases].add(new_name)
  end

  def self.add_exclusion(existing_name, excluded_name)
    init_entry(existing_name) if @@aliases[existing_name].nil?
    @@aliases[existing_name][:exclusions].add(excluded_name)
  end

  def self.has_alias?(existing_name, name_to_check)
    return false if @@aliases[existing_name].nil?
    @@aliases[existing_name][:aliases].include?(name_to_check)
  end

  def self.has_exclusion?(existing_name, name_to_check)
    return false if @@aliases[existing_name].nil?
    @@aliases[existing_name][:exclusions].include?(name_to_check)
  end

  def self.write_aliases()
    CSV.open(@@aliases_filepath, 'w') do |csv|
      @@aliases.each do |key, value|
        row = []
        row.push(key)

        value[:aliases].each do |elem|
          row.push(elem)
        end

        row.push("EXCLUSIONS")

        value[:exclusions].each do |elem|
          row.push(elem)
        end

        csv << row
      end 
    end
  end
end
