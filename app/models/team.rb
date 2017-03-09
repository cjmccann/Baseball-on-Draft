class Team < ActiveRecord::Base
  belongs_to :league

  validates :name, presence: true,
    length: { minimum: 1 }
end
