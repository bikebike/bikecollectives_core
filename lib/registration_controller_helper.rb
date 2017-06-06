require 'registration_steps'
require 'registration_controller_helper/basic_info_step_helper'
require 'registration_controller_helper/organization_step_helper'
require 'registration_controller_helper/housing_step_helper'
require 'registration_controller_helper/hosting_step_helper'
require 'registration_controller_helper/payment_step_helper'

module RegistrationControllerHelper
  def current_registration_step(conference, user)
    registration = get_registration(conference, user)
    step = registration.current_step
    return step if step && registration.send("#{step}_enabled?")
    return latest_registration_step(conference, user) 
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
    update_registration_step!(step, conference, user, params) do
      send("#{step}_step_update", registration, params)
    end
  end

  def update_registration_step!(step, conference, user, params, &block)
    begin
      result = yield
    rescue Exception => e
      logger.info e
      result = generic_registration_error e
      raise e if Rails.env.development?
    end

    registration = get_registration!(conference, user)
    registration.data ||= {}

    button = (params[:button] || '').to_sym
    if button == :back || button == :review
      registration.data['current_step'] = if button == :back
                                            registration.step_before(step)
                                          else
                                            registration.latest_step
                                          end
      registration.save

      # ignore errors when we aren't using normal navigation
      return result[:status] == :error ? { status: :complete } : result
    end

    case result[:status]
    when :complete, :warning
      # if we just completed registration
      if registration.registration_complete? && !registration.data['email_sent']
        send_registration_confirmation_email(registration)
        registration.data['email_sent'] = true
      end

      registration.data['current_step'] = registration.step_after(step)
      registration.save
    when :goto
      registration.data['current_step'] = result[:step]
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

  def get_registration!(conference, user)
    @_registration ||= {}
    @_registration["#{conference.id}:#{user.id}"] = nil
    get_registration(conference, user)
  end
end
