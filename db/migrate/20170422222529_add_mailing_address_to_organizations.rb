class AddMailingAddressToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :mailing_address, :string
  end
end
