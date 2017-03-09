class Team < ActiveRecord::Base
  belongs_to :league
  belongs_to :user

  validates :name, presence: true,
    length: { minimum: 1 }
end
