class FileData
  # TODO: store this in info in JSON and load it.

  @@files = nil

  def self.files
    if @@files.nil?
      load_file_data
    end

    @@files
  end

  def self.load_file_data
    files_path = File.expand_path(File.dirname(__FILE__) + '/../data/file_data.yml')

    @@files = YAML.load_file(files_path)
  end
end
