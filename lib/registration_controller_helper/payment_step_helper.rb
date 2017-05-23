module RegistrationControllerHelper
  def payment_type_step(registration)
    return {
      payment_method: registration.data['payment_method'] = params[:button].to_s
    }
  end

  def payment_type_step_update(registration, params)
    unless ConferenceRegistration.all_payment_methods.include?(params[:button].to_sym)
      raise "Invalid payment type #{params[:button]}"
    end
    registration.data ||= {}
    registration.data['payment_method'] = params[:button].to_s
    registration.save
    { status: :complete }
  end
  
  def payment_form_step(registration)
  end

  def payment_form_step_update(registration, params)
    value = (params[:value] || 0).to_f
    return { status: :error, message: 'amount_required' } unless value > 0

    registration.data ||= {}
    registration.data['pledge'] = value
    registration.save
    { status: :complete }
  end
end
