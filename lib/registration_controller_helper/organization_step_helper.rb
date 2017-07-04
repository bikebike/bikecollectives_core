module RegistrationControllerHelper
  def org_member_step(registration)
    return {
      org_member: (registration.data || {})['is_org_member']
    }
  end

  def org_member_review_data(registration)
    return {
      type: :bool,
      value: org_member_step(registration)[:org_member]
    }
  end

  def org_member_step_update(registration, params)
    registration.data ||= {}
    case params[:button].to_s
    when 'yes'
      registration.data['is_org_member'] = true
    when 'no'
      registration.data['is_org_member'] = false
    when 'back'
      # do nothing
    else
      raise "Unknown button error"
    end
    registration.save!
    { status: :complete }
  end

  def org_non_member_interest_step(registration)
    return {
      interest: (registration.data || {})['non_member_interest']
    }
  end

  def org_non_member_interest_review_data(registration)
    return {
      type: :text,
      value: (registration.data || {})['non_member_interest']
    }
  end

  def org_non_member_interest_step_update(registration, params)
    registration.data  ||= {}
    registration.data['non_member_interest'] = params[:interest]
    registration.save!
    return {
      status: :complete
    }
  end

  def org_location_step(registration)
    city = if (registration.data || {})['city_id'].present?
             City.find(registration.data['city_id'])
           else
             registration.city || City.from_request(request)
           end
    return {
      step_name: (registration.data || {})['is_org_member'] == false ? :your_location : :org_location,
      location: city.to_s
    }
  end

  def org_location_review_data(registration)
    data = org_location_step(registration)
    return {
      name: data[:step_name],
      value: data[:location],
      type: :string
    }
  end

  def org_location_step_update(registration, params)
    location = params[:location]
    location_name = I18n.transliterate(location.to_s).gsub(/[^\w\s]/, '').gsub(/\s\s+/, ' ').strip.downcase
    if location_name.present?
      city = City.search(params[:location])
      unless city.present?
        return {
            status: :error,
            message: 'city_not_found',
            data: { location: params[:location] }
          }
      end

      city_name = I18n.transliterate(city.to_s).gsub(/[^\w\s]/, '').gsub(/\s\s+/, ' ').strip.downcase

      if city_name == location_name
        if (registration.data || {})['city_id'].present?
          # remove this data to clear the confirmation step
          registration.data.delete('city_id')
        end
        registration.city_id = city.id
      else
        registration.data ||= {}
        registration.data['city_id'] = city.id
      end

      registration.save!
      return { status: :complete }
    end

    { status: :error, message: 'location_required' }
  end

  def org_location_confirm_step(registration)
    { city: City.find((registration.data || {})['city_id']) }
  end

  def org_location_confirm_review_data(registration)
    return { type: :none }
  end

  def org_location_confirm_step_update(registration, params)
    if params[:button].to_s == 'yes'
      registration.data ||= {}
      registration.city_id = registration.data['city_id']
      registration.save!
    end
    { status: :complete }
  end

  def org_select_step(registration)
    orgs = registration.nearby_organizations
    return {
      organizations: orgs,
      organization: orgs.find { |o| o.host?(registration.user) }
    }
  end

  def org_select_review_data(registration)
    org = registration.user.organizations.first
    return {
      type: :string,
      value: org.present? ? org.name : nil
    }
  end

  def org_select_step_update(registration, params)
    registration.data ||= {}
    if params[:button].to_s == 'create'
      registration.data['new_org'] = {}
    elsif params[:org_id].present?
      org_id = params[:org_id].to_i
      registration.data['new_org'] = nil unless (registration.data['new_org'] || {})['id'] == org_id
      org = Organization.find(org_id)
      raise "Invalid organization" unless org.near_city?(registration.city_id)
      UserOrganizationRelationship.delete_all(user_id: registration.user_id)
      registration.user.organizations << org
    end

    registration.save!

    return { status: :complete }
  end

  def org_create_name_step(registration)
    { name: ((registration.data || {})['new_org'] || {})['name'] }
  end

  def org_create_name_review_data(registration)
    return { type: :none }
  end

  def org_create_name_step_update(registration, params)
    if params[:name].to_s.strip.present?
      registration.data ||= {}
      registration.data['new_org'] ||= {}
      registration.data['new_org']['name'] = params[:name].strip
      registration.save!
      return { status: :complete }
    end
    return {
      status: :error,
      message: 'org_name_required'
    }
  end

  def org_create_address_step(registration)
    return {
      address: ((registration.data || {})['new_org'] || {})['address'],
      city: registration.city
    }
  end

  def org_create_address_review_data(registration)
    return { type: :none }
  end

  def org_create_address_step_update(registration, params)
    if params[:address].to_s.strip.present?
      registration.data ||= {}
      registration.data['new_org'] ||= {}
      registration.data['new_org']['address'] = params[:address].strip
      registration.save!
      return { status: :complete }
    end
    return {
      status: :error,
      message: 'address_required'
    }
  end

  def org_create_email_step(registration)
    { email: ((registration.data || {})['new_org'] || {})['email'] }
  end

  def org_create_email_review_data(registration)
    return { type: :none }
  end

  def org_create_email_step_update(registration, params)
    if params[:email].to_s =~ /^.+\@.+\..+$/
      if params[:email].strip.downcase == registration.user.email.downcase
        return { status: :error, message: 'org_email_matches_personal_email' }
      end
      registration.data ||= {}
      registration.data['new_org'] ||= {}
      registration.data['new_org']['email'] = params[:email].strip
      registration.save!
      return { status: :complete }
    end
    { status: :error, message: 'email_required' }
  end

  def org_create_mailing_address_step(registration)
    address = ((registration.data || {})['new_org'] || {})['mailing_address']
    if address.nil? && ((registration.data || {})['new_org'] || {})['address'].present? && (location = Location.from_city_address(registration.data['new_org']['address'], registration.city)).present?
      address = location.mailing_address
    end
    return { address: address }
  end

  def org_create_mailing_address_review_data(registration)
    return { type: :none }
  end

  def org_create_mailing_address_step_update(registration, params)
    if params[:mailing_address].to_s.strip.present?
      registration.data ||= {}
      registration.data['new_org'] ||= {}
      registration.data['new_org']['mailing_address'] = params[:mailing_address].strip

      is_new = !registration.data['new_org']['id'].present?
      org = if is_new
              Organization.new
            else
              Organization.find(registration.data['new_org']['id'])
            end
      org.name = registration.data['new_org']['name']
      org.email_address = registration.data['new_org']['email']
      org.mailing_address = registration.data['new_org']['mailing_address']
      org.save!

      if is_new
        location = Location.create(street: registration.data['new_org']['address'], city_id: registration.city_id)
        LocationsOrganization.create(location_id: location.id, organization_id: org.id)
      else
        location = org.locations.first
        location.street = registration.data['new_org']['address']
        location.city_id = registration.city_id
        location.save!
      end

      org.add_user(registration.user_id)

      registration.data['new_org']['id'] = org.id

      registration.save!
      return { status: :complete }
    end
    { status: :error, message: 'mailing_address_required' }
  end

end
