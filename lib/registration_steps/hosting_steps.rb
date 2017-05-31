module RegistrationSteps
  def hosting_check_available?(registration = self)
    registration.id.present? &&
      registration.user.present? &&
      (registration.user.organizations.present? || (registration.data || {})['is_org_member'] == false) &&
      registration.potential_provider?
  end

  def hosting_attending_available?(registration = self)
    hosting_check_available?(registration) &&
      registration.can_provide_housing != false
  end

  alias_method :hosting_address_available?,     :hosting_attending_available?
  alias_method :hosting_phone_available?,       :hosting_attending_available?
  alias_method :hosting_space_beds_available?,  :hosting_attending_available?
  alias_method :hosting_space_floor_available?, :hosting_attending_available?
  alias_method :hosting_space_tent_available?,  :hosting_attending_available?
  alias_method :hosting_start_date_available?,  :hosting_attending_available?
  alias_method :hosting_end_date_available?,    :hosting_attending_available?
  alias_method :hosting_info_available?,        :hosting_attending_available?
  alias_method :hosting_other_available?,       :hosting_attending_available?

  def hosting_check_completed?(registration = self)
    !registration.can_provide_housing.nil?
  end

  def hosting_attending_completed?(registration = self)
    !registration.is_attending.nil?
  end

  def hosting_address_completed?(registration = self)
    registration.housing_data.present? &&
      !registration.housing_data['address'].nil?
  end

  def hosting_phone_completed?(registration = self)
    registration.housing_data.present? &&
      !registration.housing_data['phone'].nil?
  end

  def hosting_space_beds_completed?(registration = self)
    registration.housing_data.present? &&
      registration.housing_data['space'].present? &&
      registration.housing_data['space']['bed_space'].present?
  end

  def hosting_space_floor_completed?(registration = self)
    registration.housing_data.present? &&
      registration.housing_data['space'].present? &&
      registration.housing_data['space']['floor_space'].present?
  end

  def hosting_space_tent_completed?(registration = self)
    registration.housing_data.present? &&
      registration.housing_data['space'].present? &&
      registration.housing_data['space']['tent_space'].present?
  end

  def hosting_start_date_completed?(registration = self)
    registration.housing_data.present? &&
      registration.housing_data['availability'].present? &&
      registration.housing_data['availability'].length > 0
  end

  def hosting_end_date_completed?(registration = self)
    registration.housing_data.present? &&
      registration.housing_data['availability'].present? &&
      registration.housing_data['availability'].length > 1
  end

  def hosting_info_completed?(registration = self)
    registration.housing_data.present? &&
      !registration.housing_data['info'].nil?
  end

  def hosting_other_completed?(registration = self)
    registration.housing_data.present? &&
      !registration.housing_data['notes'].nil?
  end
end