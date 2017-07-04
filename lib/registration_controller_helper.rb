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
      result = generic_registration_error e
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

      if registration.data['current_step'] == :review
        result[:message] ||= 'registration_complete'
      end

      registration.save
    when :goto
      registration.data['current_step'] = result[:step]
      registration.save
    end

    return result
  end

  def tabular_data(conference)
    registrations = ConferenceRegistration.where(conference_id: conference.id).sort do |a, b|
      (a.user.present? ? (a.user.firstname || '') : '').downcase <=> (b.user.present? ? (b.user.firstname || '') : '').downcase
    end
    boolean_options = [
              [I18n.t("articles.conference_registration.questions.bike.yes"), true],
              [I18n.t("articles.conference_registration.questions.bike.no"), false]
            ]

    columns = Set.new [:name, :email, :status, :date]
     column_types = {}
    keys = {}
    rows = []
    column_options = {}
    registrations.each do |r|
      row = {
        id: r.id,
        email: r.user.email,
        status: I18n.t("articles.conference_registration.terms.registration_status.#{r.status}"),
        date: r.created_at ? r.created_at.strftime("%F %T") : '' 
      }
      RegistrationSteps.all_registration_steps.each do |step|
        review_data = respond_to?("#{step}_review_data") ? send("#{step}_review_data", r) : {}
        (review_data[:table_data] || {}).each do |column_name, column_data|
          columns << column_name
          column_types[column_name] ||= column_data[:type]
          keys[column_name] ||= column_data[:key] if column_data[:key].present?
          if column_data[:type] == :list
            column_options[column_name] ||= column_data[:options].map { |o| [I18n.t("articles.conference_registration.questions.bike.#{o}", o)] }
          elsif column_data[:type] == :bool
            column_options[column_name] ||= boolean_options
          end
          row[column_name] = column_data[:value]
        end
      end
      rows << row
    end
    return {
      registrations: registrations,
      columns: columns,
      column_types: column_types,
      keys: keys,
      data: rows
    }
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
