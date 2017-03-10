class Setting < ActiveRecord::Base
  belongs_to :setting_manager
  belongs_to :league
  belongs_to :user
end
