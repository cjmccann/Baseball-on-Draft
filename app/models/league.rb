class League < ActiveRecord::Base
  belongs_to :user

  has_many :teams, dependent: :destroy
  has_one :setting_manager, dependent: :destroy
  has_one :draft_helper, dependent: :destroy

  validates :name, presence: true,
    length: { minimum: 2 }

  after_create :init_setting_manager

  def my_team
    self.teams.where( { :name => "My Team" } ).first
  end

  private
  def init_setting_manager
    self.build_setting_manager( { :user => self.user } )
    self.setting_manager.save
  end
end
