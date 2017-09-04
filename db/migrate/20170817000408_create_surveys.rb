class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.string :name
      t.string :version
      t.json :results

      t.timestamps null: false
    end
  end
end
