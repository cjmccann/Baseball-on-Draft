class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.text :fields
      t.references :league, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
