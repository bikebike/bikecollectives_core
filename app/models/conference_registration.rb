require 'registration_steps'

class ConferenceRegistration < ActiveRecord::Base
  include ::RegistrationSteps

  belongs_to :conference
  belongs_to :user
  has_many :conference_registration_responses

  AttendingOptions = [:yes, :no]

  def languages
    user.present? && user.languages.present? ? user.languages : [I18n.default_locale.to_sym]
  end

  def self.all_housing_options
    [:none, :tent, :house]
  end

  def self.all_spaces
    [:bed_space, :floor_space, :tent_space]
  end

  def self.all_bike_options
    [:yes, :no]
  end

  def self.all_food_options
    [:meat, :vegetarian, :vegan]
  end

  def self.all_considerations
    [:vegan, :smoking, :pets, :quiet]
  end

  def self.all_payment_methods
    [:paypal, :on_arrival, :none]
  end

  def self.all_languages
    User.AVAILABLE_LANGUAGES
  end

  def guests
    return nil unless can_provide_housing
  end

  def city
    unless @_city.present?
      if city_id.present?
        @_city = City.find(city_id)
      else
        city_name = read_attribute(:city)
        @_city = City.search(city_name) if city_name.present?
      end
    end
    return @_city
  end

  def attending?
    is_attending != 'n'
  end

  def checked_in?
    (data || {})['checked_in'].present?
  end

  def registered?
    status == :checked_in || status == :registered
  end

  def status
    # our user hasn't registered if their user doesn't exist or they haven't entered a city
    return :unregistered if user.nil? || user.firstname.nil?
    return :checked_in if checked_in?
    return :registered if review_enabled?
    return :incomplete
  end

  def potential_provider?
    return false unless city.present? && conference.present?
    if @_potential_provider.nil?
      conditions = conference.provider_conditions || Conference.default_provider_conditions
      @_potential_provider = City.distance_less_than(conference.city, city, (conditions['distance']['number'] || 0).to_i, conditions['distance']['unit'])
    end
    return @_potential_provider
  end

  def nearby_organizations
    return nil if city_id.nil?
    Organization.near(city_id).sort { |o1, o2| o1.name.downcase <=> o2.name.downcase }
  end

  def has_nearby_organizations?
    if @_has_nearby_organizations.nil?
      @_has_nearby_organizations = Organization.find_by_city(city_id).present? ||
                                   Organization.first_near(city_id).present?
    end
    return @_has_nearby_organizations
  end

  def from
    if user.organizations.present?
      return I18n.backend._!("#{user.organizations.first.name} (#{city.city})")
    end
    return city.to_s
  end

  def host
    if housing_data.present? && housing_data['host'].present?
      return ConferenceRegistration.find(housing_data['host'])
    end
    return nil
  end

  def guests
    space = {}
    ConferenceRegistration.where(conference_id: conference_id).select do |r|
      data = r.housing_data || {}
      if data['host'] == id
        space[data['space']] ||= []
        space[data['space']] << r
      end
    end
    return space
  end

private
  def check(field, was)
    send("#{field}#{was ? '_was' : ''}")
  end
end
