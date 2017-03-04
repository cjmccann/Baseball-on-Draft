class ModelData
  def self.models
    @@models
  end

  def self.model_weights
    @@model_weights
  end

  @@model_weights = {
    :steamer => 0.3,
    :depthcharts => 0.2,
    :pecota => 0.25,
    :zips => 0.25
  }

  @@models = {
    :steamer => {
      :bat => {
        :name => 0,
        :pa => 3,
        :h => 5,
        :doubles => 6,
        :hr => 8,
        :r => 9,
        :rbi => 10,
        :bb => 11,
        :so => 12,
        :sb => 14,
        :avg => 17,
        :obp => 18,
        :slg => 19,
        :war => 29
      },
      :pit => {
        :name => 0,
        :w => 2,
        :l => 3,
        :era => 4,
        :gs => 5,
        :sv => 7,
        :ip => 8,
        :h => 9,
        :hr => 11,
        :so => 12,
        :bb => 13,
        :whip => 14,
        :kper9 => 15,
        :bbper9 => 16,
        :fip => 17,
        :war => 18
      }
    },
    :zips => {
      :bat => {
        :name => 0,
        :pa => 3,
        :h => 5,
        :doubles => 6,
        :hr => 8,
        :r => 9,
        :rbi => 10,
        :bb => 11,
        :so => 12,
        :sb => 14,
        :avg => 16,
        :obp => 17,
        :slg => 18,
        :war => 23
      },
      :pit => {
        :name => 0,
        :w => 2,
        :l => 3,
        :era => 4,
        :gs => 5,
        :ip => 7,
        :h => 8,
        :hr => 10,
        :so => 11,
        :bb => 12,
        :whip => 13,
        :kper9 => 14,
        :bbper9 => 15,
        :fip => 16,
        :war => 17
      }
    },
    :depthcharts => {
      :bat => {
        :name => 0,
        :pa => 3,
        :h => 5,
        :doubles => 6,
        :hr => 8,
        :r => 9,
        :rbi => 10,
        :bb => 11,
        :so => 12,
        :sb => 14,
        :avg => 16,
        :obp => 17,
        :slg => 18, 
        :war => 23
      },
      :pit => {
        :name => 0,
        :w => 2,
        :l => 3,
        :sv => 4,
        :era => 6,
        :gs => 7,
        :ip => 9,
        :h => 10,
        :hr => 12,
        :so => 13,
        :bb => 14,
        :whip => 15,
        :kper9 => 16,
        :bbper9 => 17,
        :fip => 18,
        :war => 19
      }
    },
    :pecota => {
      :bat => {
        :lastname => 1, 
        :firstname => 2,
        :pos => 4,
        :pa => 14,
        :r => 17,
        :doubles => 19,
        :hr => 21,
        :h => 22,
        :rbi => 24,
        :bb => 25,
        :so => 28,
        :sb => 32,
        :avg => 34,
        :obp => 35,
        :slg => 36,
        :war => 45
      },
      :pit => {
        :lastname => 1,
        :firstname => 2,
        :w => 13,
        :l => 14,
        :sv => 17,
        :gs => 20,
        :ip => 21,
        :h => 22,
        :hr => 23,
        :bb =>  24,
        :so => 27, 
        :bbper9 => 28,
        :kper9 => 29,
        :whip => 32,
        :era => 33,
        :dra => 34,
        :war => 36
      }
    }
  }
end
