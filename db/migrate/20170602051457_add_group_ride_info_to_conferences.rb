class AddGroupRideInfoToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :group_ride_info, :text
  end
end
