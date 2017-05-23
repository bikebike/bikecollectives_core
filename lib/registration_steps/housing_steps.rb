module RegistrationSteps
  def housing_arrival_date_enabled?(registration = self)
    housing_arrival_date_available?(registration)
  end

  def housing_arrival_date_available?(registration = self)
    registration.id.present? &&
      registration.user.present? &&
      (registration.user.organizations.present? || (registration.data || {})['is_org_member'] == false) &&
      !registration.potential_provider?
  end

  alias_method :housing_departure_date_available?, :housing_arrival_date_available?
  alias_method :housing_type_available?, :housing_arrival_date_available?
  alias_method :housing_bike_available?, :housing_arrival_date_available?
  alias_method :housing_food_available?, :housing_arrival_date_available?
  # alias_method :housing_allergies_available?, :housing_arrival_date_available?
  alias_method :housing_other_available?, :housing_arrival_date_available?

  def housing_companion_check_available?(registration = self)
    housing_arrival_date_available?(registration) &&
      registration.housing == 'house'
  end

  def housing_companion_email_available?(registration = self)
    housing_companion_check_available?(registration) &&
      (registration.housing_data || {})['companion'] != false &&
      (registration.housing_data || {})['companion'] != nil
  end

  # def housing_companion_invite_available?(registration = self)
  #   housing_companion_email_available?(registration) &&
  #     ((registration.housing_data || {})['companion'] || {})['email'].present? &&
  #     ((registration.housing_data || {})['companion'] || {})['id'].nil?
  # end

  def housing_arrival_date_completed?(registration = self)
    registration.arrival.present?
  end

  def housing_departure_date_completed?(registration = self)
    registration.departure.present?
  end

  def housing_type_completed?(registration = self)
    registration.housing.present?
  end

  def housing_companion_check_completed?(registration = self)
    registration.housing_data.present? &&
      !(registration.housing_data['companion'] || {}).nil?
  end

  def housing_companion_email_completed?(registration = self)
    registration.housing_data.present? &&
      !(registration.housing_data['companion'] || {}).nil? &&
      registration.housing_data['companion']['email'].present?
  end

  # def housing_companion_invite_completed?(registration = self)
  #   registration.housing_data.present? &&
  #     !(registration.housing_data['companion'] || {}).nil? &&
  #     registration.housing_data['companion']['email'].present? &&
  #     registration.housing_data['companion']['id'].present?
  # end

  def housing_bike_completed?(registration = self)
    registration.bike.present?
  end

  def housing_food_completed?(registration = self)
    !registration.food.nil?
  end

  # def housing_allergies_completed?(registration = self)
  #   !registration.allergies.nil?
  # end

  def housing_other_completed?(registration = self)
    registration.housing_data.present? && !registration.housing_data['other'].nil?
  end
end
