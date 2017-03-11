class DraftHelper < ActiveRecord::Base
  belongs_to :league

  has_many :teams
  has_one :setting_manager
  has_many :players
end
