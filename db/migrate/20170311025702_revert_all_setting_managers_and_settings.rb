class RevertAllSettingManagersAndSettings < ActiveRecord::Migration
  def change
    drop_table :settings

    change_table :setting_managers do |t|
      t.integer :bat_C
      t.integer :bat_1B
      t.integer :bat_2B
      t.integer :bat_3B
      t.integer :bat_SS
      t.integer :bat_LF
      t.integer :bat_CF
      t.integer :bat_RF
      t.integer :bat_CI
      t.integer :bat_MI
      t.integer :bat_OF
      t.integer :bat_UTIL

      t.integer :pit_SP
      t.integer :pit_RP
      t.integer :pit_P

      t.boolean :bat_r
      t.boolean :bat_hr
      t.boolean :bat_rbi
      t.boolean :bat_sb
      t.boolean :bat_obp
      t.boolean :bat_slg
      t.boolean :bat_doubles
      t.boolean :bat_bb
      t.boolean :bat_so
      t.boolean :bat_avg
      t.boolean :bat_war

      t.boolean :pit_sv
      t.boolean :pit_hr
      t.boolean :pit_so
      t.boolean :pit_era
      t.boolean :pit_whip
      t.boolean :pit_qs
      t.boolean :pit_gs
      t.boolean :pit_w
      t.boolean :pit_l
      t.boolean :pit_h
      t.boolean :pit_bb
      t.boolean :pit_kper9
      t.boolean :pit_bbper9
      t.boolean :pit_fip
      t.boolean :pit_war
      t.boolean :pit_dra
    end
  end
end
