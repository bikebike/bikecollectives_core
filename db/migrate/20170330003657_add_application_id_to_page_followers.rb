class AddApplicationIdToPageFollowers < ActiveRecord::Migration
  def change
    add_column :page_followers, :application_id, :integer
  end
end
