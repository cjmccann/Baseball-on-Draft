class CreateDraftHelpers < ActiveRecord::Migration
  def change
    create_table :draft_helpers do |t|
      t.references :league, index: true, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps null: false
    end
  end
end
