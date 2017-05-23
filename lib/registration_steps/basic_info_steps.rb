module RegistrationSteps
  def policy_enabled?(registration = self)
    true
  end

  def policy_completed?(registration = self)
    # creation of the conference registration is itself proof of agreement
    registration.id.present?
  end

  def name_completed?(registration = self)
    registration.user.present? && registration.user.firstname.present?
  end

  def languages_completed?(registration = self)
    registration.user.present? && registration.user.languages.present?
  end

  def review_completed?(registration = self)
    false
  end
end
