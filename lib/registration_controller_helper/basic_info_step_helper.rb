module RegistrationControllerHelper
  def policy_step(registration)
    { accepted_policies: (registration.present? && registration.id.present? ? policies : []) }
  end

  def policy_review_data(registration)
    return {
      type: :bool,
      value: true
    }
  end

  def policy_step_update(registration, params)
    accepted_policies = (params[:policies] || {}).keys.map(&:to_sym)
    if params[:button].to_s == 'agree' && (policies - accepted_policies).length.zero?
      unless registration.id.present?
        last_registration_data = ConferenceRegistration.where(user_id: registration.user.id).order(created_at: :desc).limit(1).first

        # in this step, we'll try to guess a few tings about their registration using the data from the last time they registerred
        if last_registration_data.present?
          # we used to save language data directly to the registration object, if we have it here, save it to the user instance
          if last_registration_data['languages'].present? && user.languages.blank?
            registration.user.languages = JSON.parse(last_registration_data['languages'])
            registration.user.save!
          end

          # use the same city they had last time          
          registration.city = last_registration_data.city if last_registration_data.city.present?
        end
      end

      registration.save

      return { status: :complete }
    end

    {
      status: :error,
      message: 'policy_required',
      data: {
        accepted_policies: accepted_policies
      }
    }
  end
  
  def name_step(registration)
    { name: registration.user.firstname || registration.user.username }
  end

  def name_review_data(registration)
    return {
      type: :string,
      value: name_step(registration)[:name]
    }
  end

  def name_step_update(registration, params)
    name = params[:name].to_s.squish
    if name.present?
      registration.user.firstname = name
      registration.user.save
      return { status: :complete }
    end
    {
      status: :error,
      message: 'name_required',
      data: { name: params[:name] }
    }
  end
  
  def languages_step(registration)
    return { 
      languages: (registration.user.languages || [I18n.locale]).map(&:to_sym)
    }
  end

  def languages_review_data(registration)
    return {
      type: :list,
      value: languages_step(registration)[:languages],
      key: "languages"
    }
  end

  def languages_step_update(registration, params)
    languages = (params[:languages] || {}).keys.select do |l|
      ConferenceRegistration.all_languages.include?(l.to_sym)
    end
    if languages.present?
      registration.user.languages = languages
      registration.user.save
      return { status: :complete }
    end
    { status: :error, message: 'language_required' }
  end

  def review_step(registration)
    data = {}
    registration.completed_steps.each do |step|
      data[step] = send("#{step}_review_data", registration)
    end
    potential_provider = registration.potential_provider?
    return {
      step_data: data,
      is_attending: registration.attending?,
      allow_cancel_attendance: registration.attending? && !potential_provider,
      allow_reopen_attendance: !registration.attending? && !potential_provider
    }
  end

  def review_step_update(registration, params)
    if params[:edit_step]
      return {
        status: :goto,
        step: params[:edit_step]
      }
    end

    if params[:button].to_s == 'cancel_registration'
      registration.is_attending = 'n'
    elsif params[:button].to_s == 'reopen_registration'
      registration.is_attending = 'y'
    end
    registration.save
    return { status: :complete }
  end
end
