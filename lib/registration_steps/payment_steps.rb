module RegistrationSteps
  def payment_type_available?(registration = self)
    registration.attending?
  end

  def payment_type_completed?(registration = self)
    (registration.data || {})['payment_method'].present?
  end

  def payment_form_available?(registration = self)
    payment_type_available?(registration) &&
      (registration.data || {})['payment_method'].present? &&
      (registration.data || {})['payment_method'] != 'none'
  end

  def payment_form_completed?(registration = self)
    registration.registration_fees_paid.present? || (registration.data || {})['pledge'].present?
  end
end