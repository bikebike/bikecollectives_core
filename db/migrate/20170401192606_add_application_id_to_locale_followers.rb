class AddApplicationIdToLocaleFollowers < ActiveRecord::Migration
  def change
    add_column :locale_followers, :application_id, :integer
  end
end
