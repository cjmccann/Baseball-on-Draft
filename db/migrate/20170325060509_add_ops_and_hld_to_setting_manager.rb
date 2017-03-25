class AddOpsAndHldToSettingManager < ActiveRecord::Migration
  def change
    add_column :setting_managers, :pit_hld, :boolean
    add_column :setting_managers, :bat_ops, :boolean
  end
end
