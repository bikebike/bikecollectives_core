module RegistrationControllerHelper
  def housing_arrival_date_step(registration)
    return {
      date: registration.arrival,
      city: registration.conference.city,
      min_date: registration.conference.min_arrival_date.to_date,
      max_date: registration.conference.max_departure_date.to_date,
      conference_start_date: registration.conference.start_date,
      conference_end_date: registration.conference.end_date
    }
  end

  def housing_arrival_date_step_update(registration, params)
    if params[:date].present?
      registration.arrival = Date.parse(params[:date])
      if registration.departure.present? && registration.arrival > registration.departure
        return {
          status: :error,
          message: 'departure_date_before_arrival',
          data: { date: registration.arrival }
        }
      end
      min_date = registration.conference.min_arrival_date
      max_date = registration.conference.max_departure_date
      if registration.arrival < min_date || registration.arrival > max_date
        raise "Date #{registration.departure} must be between #{min_date} and #{max_date}"
      end
      registration.save
      return { status: :complete }
    end
    { status: :error, message: 'arrival_date_required' }
  end

  def housing_departure_date_step(registration)
    return {
      date: registration.departure,
      city: registration.conference.city,
      min_date: registration.conference.min_arrival_date.to_date,
      max_date: registration.conference.max_departure_date.to_date,
      conference_start_date: registration.conference.start_date,
      conference_end_date: registration.conference.end_date
    }
  end

  def housing_departure_date_step_update(registration, params)
    if params[:date].present?
      registration.departure = Date.parse(params[:date])
      if registration.arrival.present? && registration.arrival > registration.departure
        return {
          status: :error,
          message: 'departure_date_before_arrival',
          data: { date: registration.departure }
        }
      end
      min_date = registration.conference.min_arrival_date
      max_date = registration.conference.max_departure_date
      if registration.departure < min_date || registration.departure > max_date
        raise "Date #{registration.departure} must be between #{min_date} and #{max_date}"
      end
      registration.save
      return { status: :complete }
    end
    { status: :error, message: 'departure_date_required' }
  end

  def housing_type_step(registration)
    return {
      housing: registration.housing.present? ? registration.housing.to_sym : nil,
      city: registration.conference.city,
      housing_types: ConferenceRegistration.all_housing_options
    }
  end

  def housing_type_step_update(registration, params)
    unless ConferenceRegistration.all_housing_options.include?(params[:button].to_sym)
      raise "Invalid housing type '#{params[:button]}'"
    end
    registration.housing = params[:button].to_s
    registration.save
    { status: :complete }
  end

  def housing_companion_check_step(registration)
    return {
      has_companion: registration.housing_data['companion'].nil? ? nil : registration.housing_data['companion'] != false
    }
  end

  def housing_companion_check_step_update(registration, params)
    registration.housing_data ||= {}
    case params[:button].to_s
    when 'yes'
      registration.housing_data['companion'] = {}
    when 'no'
      registration.housing_data['companion'] = false
    end
    registration.save unless registration.housing_data['companion'].nil?
    { status: :complete }
  end

  def housing_companion_email_step(registration)
    { email: (registration.housing_data['companion'] || {})['email'] }
  end

  def housing_companion_email_step_update(registration, params)
    email = params[:email].to_s.strip.downcase
    if email.present? && email =~ /^.+\@.+\..+$/
      registration.housing_data['companion']['email'] = email
      new_user = User.find_user(email) || User.new(email: email)

      if registration.housing_data['companion']['id'].present?
        old_user = User.find(registration.housing_data['companion']['id'])
        # make sure we can send te invite email again if this is actually a different user
        if new_user.email != old_user.email.to_str.downcase
          registration.housing_data['companion'].delete('id')
        end
      end

      if new_user.id.present?
        companion_registration = registration.conference.registration_for(new_user)

        if companion_registration.present?
          companion_companion = (companion_registration.housing_data || {})['companion']
          if (companion_companion && companion_companion['id'].present? && companion_companion['id'].to_i != registration.user_id) ||
              (companion_companion && companion_companion['id'].nil? && companion_companion['email'] != registration.user.email.strip.downcase)

            registration.housing_data['companion']['id'] = new_user.id
            registration.save

            return {
              status: :error,
              message: 'companion_already_has_companion',
              data: { email: email }
            }
          end
          return {
            status: :complete,
            message: 'companion_registerred',
            data: { email: email }
          }
        end
      end
      registration.save
      return { status: :complete }
    end
    { status: :error, message: 'companion_email_required' }
  end

  def housing_companion_invite_step(registration)
    return {
      email: (registration.housing_data['companion'] || {})['email']
    }
  end

  def housing_companion_invite_step_update(registration, params)
    if params[:button].to_s == 'next'
      unless ActionView::Base.full_sanitizer.sanitize(params[:message]).strip.present?
        return { status: :error, message: 'companion_message_required' }
      end
      user = User.create(email: registration.housing_data['companion']['email'])
      registration.housing_data['companion']['id'] = user.id
      registration.save
      send_invitation(user, registration.user, params[:message])
    end
    { status: :complete }
  end

  def housing_bike_step(registration)
    return {
      bike: registration.bike
    }
  end

  def housing_bike_step_update(registration, params)
    unless ConferenceRegistration.all_bike_options.include?(params[:button].to_sym)
      raise "Invalid bike option: #{params[:bike]}"
    end
    registration.bike = params[:button].to_s
    registration.save
    { status: :complete }
  end

  def housing_food_step(registration)
    return {
      food: registration.food
    }
  end

  def housing_food_step_update(registration, params)
    unless ConferenceRegistration.all_food_options.include?(params[:button].to_sym)
      raise "Invalid food option #{params[:button]}"
    end
    registration.food = params[:button].to_s
    registration.save
    { status: :complete }
  end

  def housing_allergies_step(registration)
    { allergies: registration.allergies }
  end

  def housing_allergies_step_update(registration, params)
    registration.allergies = params[:allergies] || ''
    registration.save
    { status: :complete }
  end

  def housing_other_step(registration)
    { allergies: registration.other }
  end

  def housing_other_step_update(registration, params)
    registration.other = params[:other] || ''
    registration.save
    { status: :complete }
  end

end
