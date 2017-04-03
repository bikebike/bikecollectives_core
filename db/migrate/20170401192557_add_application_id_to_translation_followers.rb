class AddApplicationIdToTranslationFollowers < ActiveRecord::Migration
  def change
    add_column :translation_followers, :application_id, :integer
  end
end
