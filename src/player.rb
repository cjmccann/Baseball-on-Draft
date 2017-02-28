class Player
  attr_accessor :name, :value, :stats

  def initialize(data, model, type)
    @name = nil

    @stats = {
      :steamer => { },
      :depthcharts => { },
      :pecota => { }
    }
    process_data(data, model, type)
  end

  def process_data(data, model, type)
    curr_model = ModelData.models[model][type]

    if model == :steamer || model == :depthcharts
      @name = data[curr_model[:name]]
    elsif @name == nil
      @name = "BP-ONLY"
    end

    curr_model.each do |key, value|
      @stats[model][key] = data[value]
    end
  end
end
