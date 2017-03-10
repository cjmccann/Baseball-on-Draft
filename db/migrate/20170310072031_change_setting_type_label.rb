class ChangeSettingTypeLabel < ActiveRecord::Migration
  def change
    remove_column :settings, :type

    add_column :settings, :setting_type, :string
  end
end
