Dir[File.join(Rails.root, 'lib', 'stats', '**', '*.rb')].each { |f| require f }

class DraftHelper < ActiveRecord::Base
  after_save :generate_stats

  belongs_to :league
  belongs_to :user

  has_one :setting_manager
  has_many :teams
  has_many :players, dependent: :destroy

  def regenerate
  end

  private
  def generate_stats
    LeagueSettings.set_league_settings(self.league.setting_manager.convert_all_settings_to_hash)
    parser = ProjectionParser.new(self)
    @data_manager = DataManager.new(parser)
    binding.pry
  end
end
