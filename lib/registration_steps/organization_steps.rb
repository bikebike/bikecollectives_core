module RegistrationSteps
  def is_org_member?(registration = self)
    (registration.user.present? && registration.user.organizations.present?) || (registration.data || {})['is_org_member']
  end

  def org_member_available?(registration = self)
    registration.present?
  end

  def org_member_completed?(registration = self)
    !is_org_member?(registration).nil?
  end

  def org_location_available?(registration = self)
    !(registration.data || {})['is_org_member'].nil?
  end

  def org_location_completed?(registration = self)
    registration.city_id.present? ||
      (registration.data || {})['city_id'].present?
  end

  def org_location_confirm_available?(registration = self)
    (registration.data || {})['city_id'].present?
  end

  def org_location_confirm_completed?(registration = self)
    registration.city_id.present?
  end

  def org_non_member_interest_available?(registration = self)
    (registration.data || {})['is_org_member'] == false && !registration.potential_provider?
  end

  def org_non_member_interest_completed?(registration = self)
    !(registration.data || {})['non_member_interest'].nil?
  end

  def org_select_available?(registration = self)
    org_location_available?(registration) &&
      (registration.data || {})['is_org_member'] != false
      registration.city_id.present? &&
      registration.nearby_organizations.present?
  end

  def org_select_completed?(registration = self)
    registration.user.present? &&
      (registration.user.organizations.present? ||
        (registration.data || {})['new_org'])
  end

  def org_create_address_available?(registration = self)
    org_location_available?(registration) &&
    (registration.data || {})['is_org_member'] != false &&
      (
        (registration.data || {})['new_org'] ||
        (registration.city_id.present? && registration.nearby_organizations.empty?)
      )
  end

  def org_create_address_completed?(registration = self)
    ((registration.data || {})['new_org'] || {})['address'].present?
  end

  def org_create_name_available?(registration = self)
    org_create_address_available?(registration)
  end

  def org_create_name_completed?(registration = self)
    ((registration.data || {})['new_org'] || {})['name'].present?
  end

  def org_create_email_available?(registration = self)
    org_create_address_available?(registration)
  end

  def org_create_email_completed?(registration = self)
    ((registration.data || {})['new_org'] || {})['email'].present?
  end

  def org_create_mailing_address_available?(registration = self)
    org_create_address_available?(registration)
  end

  def org_create_mailing_address_completed?(registration = self)
    ((registration.data || {})['new_org'] || {})['mailing_address'].present?
  end
end
