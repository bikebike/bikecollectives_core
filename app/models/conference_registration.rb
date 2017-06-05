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

  def city
    @_city ||= city_id.present? ? City.find(city_id) : nil
    return @_ciity
  end

  def attending?
    is_attending != 'n'
  end

  def status(was = false)
    # our user hasn't registered if their user doesn't exist or they haven't entered a city
    return :unregistered if user.nil? || check(:city, was).blank?

    # registration completes once a guest has entered a housing preference or
    #   a housing provider has opted in or out of providing housing
    return :preregistered unless
      check(:housing, was).present? || !check(:can_provide_housing, was).nil?

    # they must be registered
    return :registered
  end

  def potential_provider?
    return false unless city.present? && conference.present?
    if @_potential_provider.nil?
      Rack::MiniProfiler.step("potential_provider?") do
        conditions = conference.provider_conditions || Conference.default_provider_conditions
        @_potential_provider = City.distance_less_than(conference.city, city, conditions['distance']['number'], conditions['distance']['unit'])
      end
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

private
  def check(field, was)
    send("#{field}#{was ? '_was' : ''}")
  end
end
