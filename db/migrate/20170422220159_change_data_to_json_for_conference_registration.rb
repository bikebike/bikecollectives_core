require 'json'

class ChangeDataToJsonForConferenceRegistration < ActiveRecord::Migration
  def change
    data = {}
    ConferenceRegistration.where.not(data: nil).each do |registration|
      data[registration.id] = JSON.parse(registration.data)
    end
    remove_column :conference_registrations, :data
    add_column :conference_registrations, :data, :json
    ConferenceRegistration.where(id: data.keys).each do |registration|
      registration.data = data[registration.id]
      registration.save
    end
  end
end
