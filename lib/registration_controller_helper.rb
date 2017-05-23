require 'registration_steps'
require 'registration_controller_helper/basic_info_step_helper'
require 'registration_controller_helper/organization_step_helper'
require 'registration_controller_helper/housing_step_helper'
# require 'registration_controller_helper/hosting_step_helper'
require 'registration_controller_helper/payment_step_helper'

module RegistrationControllerHelper
  def current_registration_step(conference, user)
    get_registration(conference, user).current_step || latest_registration_step(conference, user)
  end

  def latest_registration_step(conference, user)
    get_registration(conference, user).latest_step || RegistrationSteps.all_registration_steps.first
  end

  def registration_step(step, conference, user)
    return :unauthorized unless user
    return :not_found unless RegistrationSteps.is_step?(step)
    registration = get_registration(conference, user)
    result = send("#{step}_step", registration)

    return result
  end

  def update_registration_step(step, conference, user, params)
    return :unauthorized unless user
    registration = get_registration(conference, user)

    return generic_registration_error unless RegistrationSteps.is_step?(step) &&
                                             registration.send("#{step}_enabled?")

    result = begin
               send("#{step}_step_update", registration, params)
             rescue Exception => e
               generic_registration_error e
             end

    registration.data ||= {}

    if (params[:button] || '').to_sym == :back
      registration.data['current_step'] = registration.step_before(step)
      registration.save
      if result[:status] == :error
        return { status: :complete }
      end

      return result
    end

    case result[:status]
    when :complete
      registration.data['current_step'] = registration.step_after(step)
      registration.save
    end

    return result
  end

private

  def generic_registration_error(exception = nil)
    { status: :error, message: 'generic', exception: exception }
  end

  def get_registration(conference, user)
    @_registration ||= {}
    @_registration["#{conference.id}:#{user.id}"] ||= 
      ConferenceRegistration.find_by(user_id: user.id, conference_id: conference.id) ||
        ConferenceRegistration.new(user_id: user.id, conference_id: conference.id)
  end
end
