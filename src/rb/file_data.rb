class FileData
  @@files = {
    'projections/bat-steamer.csv' => { :model => :steamer, :type => :bat },
    'projections/bat-depthcharts.csv' => { :model => :depthcharts, :type => :bat },
    'projections/bat-pecota.csv' => { :model => :pecota, :type => :bat },
    'projections/pit-steamer.csv' => { :model => :steamer, :type => :pit },
    'projections/pit-depthcharts.csv' => { :model => :depthcharts, :type => :pit },
    'projections/pit-pecota.csv' => { :model => :pecota, :type => :pit}
  }

  def self.files
    @@files
  end
end
