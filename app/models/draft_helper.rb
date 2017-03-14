class DraftHelper < ActiveRecord::Base
  before_create :generate_stats

  belongs_to :league
  belongs_to :user

  has_one :setting_manager
  has_many :teams
  has_many :players, dependent: :destroy

  def regenerate
    binding.pry
  end

  private
  def generate_stats


  end
end
