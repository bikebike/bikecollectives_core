require 'json'
require 'yaml'

class ChangeDataToJsonForConferenceRegistration < ActiveRecord::Migration
  def change
    data = {}
    ConferenceRegistration.where.not(data: nil).each do |registration|
      begin
        data[registration.id] = JSON.parse(registration.data)
      rescue
        begin
          data[registration.id] = YAML.parse(registration.data)
        rescue
          puts "Error parsing #{registration.data}"
        end
      end
    end
    remove_column :conference_registrations, :data
    add_column :conference_registrations, :data, :json
    ConferenceRegistration.where(id: data.keys).each do |registration|
      if data[registration.id].present?
        begin
          registration.data = data[registration.id]
          registration.save
        rescue
          puts "Eror saving data as JSON #{data[registration.id]}"
        end
      end
    end
  end
end
