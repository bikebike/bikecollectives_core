class CreateLocaleFollowers < ActiveRecord::Migration
  def change
    create_table :locale_followers do |t|
      t.string :locale
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
