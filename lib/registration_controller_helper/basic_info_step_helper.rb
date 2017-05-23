module RegistrationControllerHelper
  def policy_step(registration)
    { accepted_policies: (registration.present? && registration.id.present? ? policies : []) }
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
end
