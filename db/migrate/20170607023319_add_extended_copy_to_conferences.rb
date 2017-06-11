class AddExtendedCopyToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :housing_info, :text
    add_column :conferences, :workshop_info, :text
    add_column :conferences, :schedule_info, :text
    add_column :conferences, :city_info, :text
    add_column :conferences, :what_to_bring, :text
    add_column :conferences, :volunteering_info, :text
  end
end
