require 'rest_client'

module RegistrationControllerHelper
  def payment_type_step(registration)
    return {
      payment_method: registration.data['payment_method'],
      payment_methods: ConferenceRegistration.all_payment_methods
    }
  end

  def payment_type_review_data(registration)
    data = payment_type_step(registration)
    return {
      type: :enum,
      value: data[:payment_method],
      options: data[:payment_methods]
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
    payment_method = registration.data['payment_method'].to_sym
    
    if payment_method == :paypal
      currency = registration.data['payment_currency']
      currencies = Conference.default_currencies
      unless currency.present?
        currency = registration.city.country == 'CA' ? :CAD : :USD
      end      
    else
      currency = registration.conference.city.country == 'CA' ? :CAD : :USD
      currencies = [currency]
    end

    return {
      method: payment_method,
      amount: registration.data['payment_amount'],
      amounts: registration.conference.payment_amounts || Conference.default_payment_amounts,
      currencies: currencies,
      currency: currency.to_sym,
      no_ajax: true
    }
  end

  def payment_form_review_data(registration)
    data = payment_form_step(registration)
    return {
      type: :currency,
      value: data[:amount],
      currency: data[:currency]
    }
  end

  def payment_form_step_update(registration, params)
    # don't do anything if we're not completing payment now
    if params[:button] == 'back' || params[:button] == 'review'
      return { status: :complete }
    end

    if params[:token]
      details = paypal_request.details(params[:token])
      confirm_amount = details.amount.total
      confirm_currency = details.currency_code
      registration.payment_info = {
          payer_id: params[:PayerID],
          token:    params[:token],
          amount:   confirm_amount,
          currency: confirm_currency
        }.to_yaml
      registration.save
      
      return {
          status: :paypal_confirm,
          data: {
            confirm_amount: confirm_amount,
            confirm_currency: confirm_currency
          }
        }
    else
      value = (params[:value] || params[:custom_value] || 0).to_f
      unless value > 0
        return {
          status: :error,
          message: 'amount_required'
        }
      end
    end

    status = :complete
    data = nil

    if registration.data['payment_method'].to_sym == :paypal
      currency = params[:currency]
      registration.data['payment_currency'] = currency
      token = Digest::SHA256.hexdigest(rand(Time.now.to_f * 1000000).to_i.to_s)
      registration.payment_confirmation_token = token
      if Rails.env.test? || Rails.env.development?
        registration.payment_info = {
            amount:   value,
            currency: currency
          }.to_yaml
        registration.save
        status = :paypal_confirm
        data = {
            confirm_amount: value,
            confirm_currency: currency,
            test_token: 'token'
          }
      else
        status = :paypal_redirect
        data = {
          request: paypal_request(registration.conference),
          amount: value,
          currency: currency,
          confirm_args: { pp: :t, t: token },
          cancel_args: { pp: :f, t: token }
        }
      end
    end

    registration.data ||= {}
    registration.data['payment_amount'] = value
    registration.save

    return { status: status, data: data }
  end

  def paypal_payment_confirm(conference, user, params)
    registration = get_registration(conference, user)

    if Rails.env.test? || Rails.env.development?
      details = YAML.load(registration.payment_info)
      return {
        confirm_amount: details['amount'],
        confirm_currency: details['currency']
      }
    end

    details = paypal_request(conference).details(params[:token])
    amount = details.amount.total
    currency = details.currency_code

    registration.payment_info = {
        payer_id: params[:PayerID],
        token:    params[:token],
        amount:   amount,
        currency: currency
      }.to_yaml

    registration.save

    return {
      confirm_amount: amount,
      confirm_currency: currency
    }
  end

  def paypal_payment_request_data(conference, user)
    return YAML.load(get_registration(conference, user).payment_info)
  end

  def paypal_payment_complete(paypal_payment_response, conference, user, params)
    unless params[:button] == 'confirm'
      return {
        status: :error,
        message: 'payment_cancelled'
      }
    end
    registration = get_registration(conference, user)
    info = YAML.load(get_registration(conference, user).payment_info)
    if Rails.env.test? || Rails.env.development?
      status = registration.data['payment_status'] || 'Completed'
      amount = info[:amount]
      currency = info[:currency_code]
    else
      paypal = paypal_request(conference).checkout!(info[:token], info[:payer_id], paypal_payment_response)
      payment_info = paypal.payment_info.first
      status = payment_info.payment_status
      amount = payment_info.amount.total
      currency = payment_info.currency_code
    end

    if status == 'Denied'
      return {
        status: :error,
        message: 'payment_denied'
      }
    end

    if status == 'Completed' || status == 'Pending'
      registration.registration_fees_paid ||= 0
      registration.registration_fees_paid += amount
      registration.data['current_step'] = registration.step_after(:payment_form)

      registration.save

      if status == 'Pending'
        return {
          status: :warning,
          message: 'payment_pending'
        }
      end

      return {
        status: :complete,
        message: 'payment_processed'
      }
    end

    raise "Payment error"
  end

private

  def paypal_request(conference)
    Paypal::Express::Request.new(
      username:  conference.paypal_username,
      password:  conference.paypal_password,
      signature: conference.paypal_signature
    )
  end

end
