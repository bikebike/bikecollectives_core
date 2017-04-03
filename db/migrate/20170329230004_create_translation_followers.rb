class CreateTranslationFollowers < ActiveRecord::Migration
  def change
    create_table :translation_followers do |t|
      t.string :key
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
