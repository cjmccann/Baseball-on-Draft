class League < ActiveRecord::Base
  belongs_to :user

  has_many :teams, dependent: :destroy
  has_one :setting_manager, dependent: :destroy

  validates :name, presence: true,
    length: { minimum: 5 }
end
