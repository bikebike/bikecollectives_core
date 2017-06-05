module RegistrationControllerHelper
  def hosting_check_step(registration)
    return {
      can_provide_housing: registration.can_provide_housing,
      city: registration.conference.city,
      max_date: registration.conference.min_arrival_date.to_date,
      min_date: registration.conference.max_departure_date.to_date
    }
  end

  def hosting_check_review_data(registration)
    return {
      type: :bool,
      value: hosting_check_step(registration)[:can_provide_housing]
    }
  end

  def hosting_check_step_update(registration, params)
    case params[:button].to_s
    when 'yes'
      registration.can_provide_housing = true
    when 'no'
      registration.can_provide_housing = false
    end

    registration.save! unless registration.can_provide_housing.nil?

    return { status: :complete }
  end

  def hosting_attending_step(registration)
    return {
      is_attending: registration.attending?
    }
  end

  def hosting_attending_review_data(registration)
    return {
      type: :bool,
      value: hosting_attending_step(registration)[:is_attending]
    }
  end

  def hosting_attending_step_update(registration, params)
    case params[:button].to_s
    when 'yes'
      registration.is_attending = 'y'
    when 'no'
      registration.is_attending = 'n'
    end

    registration.save! unless registration.is_attending.nil?

    return { status: :complete }
  end

  def hosting_address_step(registration)
    return {
      address: (registration.housing_data || {})['address'],
      city: registration.city
    }
  end

  def hosting_address_review_data(registration)
    return {
      type: :string,
      value: hosting_address_step(registration)[:address]
    }
  end

  def hosting_address_step_update(registration, params)
    unless params[:address].present?
      return {
        status: :error,
        message: 'address_required'
      }
    end

    registration.housing_data ||= {}
    registration.housing_data['address'] = params[:address]
    registration.save!

    return { status: :complete }
  end

  def hosting_phone_step(registration)
    return {
      phone: (registration.housing_data || {})['phone']
    }
  end

  def hosting_phone_review_data(registration)
    return {
      type: :string,
      value: registration.housing_data['phone']
    }
  end

  def hosting_phone_step_update(registration, params)
    phone = params[:phone]
    unless phone.present? && phone =~ /^[\d\-\(\)\s\+]+$/ && phone.gsub(/[^\d]/, '').length > 9
      return {
        status: :error,
        message: 'phone_required',
        data: { phone: phone }
      }
    end

    registration.housing_data['phone'] = phone
    registration.save!

    return { status: :complete }
  end

  def hosting_space_beds_step(registration)
    return {
      bed_space: ((registration.housing_data || {})['space'] || {})['bed_space']
    }
  end

  def hosting_space_beds_review_data(registration)
    return {
      type: :number,
      value: hosting_space_beds_step(registration)[:bed_space]
    }
  end

  def hosting_space_beds_step_update(registration, params)
    bed_space = params[:bed_space].to_s
    if bed_space.length < 1 || bed_space =~ /[^\d]/ || bed_space.to_i < 0
      return {
        status: :error,
        message: 'bed_space_required',
        data: { bed_space: bed_space }
      }
    end

    registration.housing_data['space'] ||= {}
    registration.housing_data['space']['bed_space'] = bed_space.to_i
    registration.save!

    return { status: :complete }
  end

  def hosting_space_floor_step(registration)
    return {
      floor_space: ((registration.housing_data || {})['space'] || {})['floor_space']
    }
  end

  def hosting_space_floor_review_data(registration)
    return {
      type: :number,
      value: hosting_space_floor_step(registration)[:floor_space]
    }
  end

  def hosting_space_floor_step_update(registration, params)
    floor_space = params[:floor_space].to_s
    if floor_space.length < 1 || floor_space =~ /[^\d]/ || floor_space.to_i < 0
      return {
        status: :error,
        message: 'floor_space_required',
        data: { floor_space: floor_space }
      }
    end

    registration.housing_data['space'] ||= {}
    registration.housing_data['space']['floor_space'] = floor_space.to_i
    registration.save!

    return { status: :complete }
  end

  def hosting_space_tent_step(registration)
    tent_space = ((registration.housing_data || {})['space'] || {})['tent_space']
    return {
      tent_space: tent_space.present? && tent_space > 0
    }
  end

  def hosting_space_tent_review_data(registration)
    return {
      type: :bool,
      value: hosting_space_tent_step(registration)[:tent_space]
    }
  end

  def hosting_space_tent_step_update(registration, params)
    case params[:button].to_s
    when 'yes'
      # we're going to hard code this as 5 for now until we have time to implement more complex logic
      registration.housing_data['space']['tent_space'] = 5
    when 'no'
      registration.housing_data['space']['tent_space'] = 0
    end

    registration.save!

    return { status: :complete }
  end

  def hosting_start_date_step(registration)
    return {
      date: (registration.housing_data['availability'] || [])[0],
      min_date: registration.conference.min_arrival_date.to_date,
      max_date: registration.conference.max_departure_date.to_date,
      conference_start_date: registration.conference.start_date,
      conference_end_date: registration.conference.end_date
    }
  end

  def hosting_start_date_review_data(registration)
    return {
      type: :date,
      value: (registration.housing_data['availability'] || [])[0]
    }
  end

  def hosting_start_date_step_update(registration, params)
    if params[:date].present?
      registration.housing_data['availability'] ||= [nil, nil]
      registration.housing_data['availability'][0] = Date.parse(params[:date])
      end_date = registration.housing_data['availability'][1]
      end_date = Date.parse(end_date) if end_date.is_a?(String)
      if end_date.present? && registration.housing_data['availability'][0] > end_date
        return {
          status: :error,
          message: 'end_date_before_start',
          data: { date: registration.housing_data['availability'][0] }
        }
      end
      min_date = registration.conference.min_arrival_date
      max_date = registration.conference.max_departure_date
      if registration.housing_data['availability'][0] < min_date || registration.housing_data['availability'][0] > max_date
        raise "Date #{registration.housing_data['availability'][1]} must be between #{min_date} and #{max_date}"
      end
      registration.save!
      return { status: :complete }
    end
    { status: :error, message: 'start_date_required' }
  end

  def hosting_end_date_step(registration)
    return {
      date: (registration.housing_data['availability'] || [])[1],
      min_date: registration.conference.min_arrival_date.to_date,
      max_date: registration.conference.max_departure_date.to_date,
      conference_start_date: registration.conference.start_date,
      conference_end_date: registration.conference.end_date
    }
  end

  def hosting_end_date_review_data(registration)
    return {
      type: :date,
      value: (registration.housing_data['availability'] || [])[1]
    }
  end

  def hosting_end_date_step_update(registration, params)
    if params[:date].present?
      registration.housing_data['availability'] ||= [nil, nil]
      start_date = registration.housing_data['availability'][0]
      start_date = Date.parse(start_date) if start_date.is_a?(String)
      registration.housing_data['availability'][1] = Date.parse(params[:date])
      if start_date.present? && start_date > registration.housing_data['availability'][1]
        return {
          status: :error,
          message: 'end_date_before_start',
          data: { date: registration.housing_data['availability'][1] }
        }
      end
      min_date = registration.conference.min_arrival_date
      max_date = registration.conference.max_departure_date
      if registration.housing_data['availability'][1] < min_date || registration.housing_data['availability'][1] > max_date
        raise "Date #{registration.housing_data['availability'][1]} must be between #{min_date} and #{max_date}"
      end
      registration.save!
      return { status: :complete }
    end
    { status: :error, message: 'end_date_required' }
  end

  def hosting_info_step(registration)
    return {
      info: registration.housing_data['info']
    }
  end

  def hosting_info_review_data(registration)
    return {
      type: :html,
      value: hosting_info_step(registration)[:info]
    }
  end

  def hosting_info_step_update(registration, params)
    unless ActionView::Base.full_sanitizer.sanitize(params[:info] || '').gsub(/\s/, '').present?
      return {
        status: :error,
        message: 'info_required',
        data: { info: params[:info] }
      }
    end

    registration.housing_data ||= {}
    registration.housing_data['info'] = params[:info]
    registration.save!

    return { status: :complete }
  end

  def hosting_other_step(registration)
    return {
      other: registration.housing_data['notes']
    }
  end

  def hosting_other_review_data(registration)
    return {
      type: :text,
      value: hosting_other_step(registration)[:other]
    }
  end

  def hosting_other_step_update(registration, params)
    registration.housing_data['notes'] = params[:other]
    return { status: :complete }
  end
end
