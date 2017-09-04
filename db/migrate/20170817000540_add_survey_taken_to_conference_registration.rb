class AddSurveyTakenToConferenceRegistration < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :survey_taken, :boolean
  end
end
