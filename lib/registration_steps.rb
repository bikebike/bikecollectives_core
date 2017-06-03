require 'registration_steps/basic_info_steps'
require 'registration_steps/organization_steps'
require 'registration_steps/housing_steps'
require 'registration_steps/hosting_steps'
require 'registration_steps/payment_steps'

module RegistrationSteps
  # order all possible steps during registration
  def self.all_registration_steps
    [
      :policy,       # agree to the policy
      :name,         # enter your name
      :languages,    # select spoken languages
      
      :org_member,   # Do you work for or volunteer with a bike collective?
      :org_location, # Where is your collective located?
      :org_location_confirm,    # Confirm your location
      :org_non_member_interest, # What is your interest in attending Bike!Bike!?
      :org_select,         # Which organization in [city] are you associated with?
      :org_create_name,    # What is the name of your organization?
      :org_create_address, # Where in [city] is your organization located?
      :org_create_email,   # What is the organization's email address
      :org_create_mailing_address, # How can we contact your organization by snail mail?

      :hosting_check,       # Are you willing to have guests stay at your home during the conference?
      :hosting_attending,   # Will you be attending the conference yourself?
      :hosting_address,     # What is your street address?
      :hosting_phone,       # What is your phone number?
      :hosting_space_beds,  # How many people can you host on beds or couches?
      :hosting_space_floor, # How much floor-space do you have?
      :hosting_space_tent,  # How many tents could you support in your yard-space?
      :hosting_start_date,  # What is the earliest date that you would be willing to host guests from?
      :hosting_end_date,    # What is the latest date that you would be willing to host guests to?
      :hosting_info,        # What are your house rules?
      :hosting_other,       # Any other consideration that we should keep in mind?

      :housing_arrival_date,    # When will you be arriving in [city]?
      :housing_departure_date,  # When are you planning to leave [city]?
      :housing_type,            # Do you need a place to stay in [city]?
      :housing_companion_check, # Will you be coming with a significant other? 
      :housing_companion_email, # Enter your companion's email address
      :housing_food,  # What are your eating habits?
      :housing_bike,  # Would you like to borrow a bike?
      :group_ride,    # Do you plan on attending the group ride?
      :housing_other, # Is there anything else that we should be aware of?

      :payment_type, # Would you like to pay now via PayPal or pledge to pay later
      :payment_form, # Make a payment

      :review
    ]
  end

  def self.is_step?(step)
    RegistrationSteps.all_registration_steps.include?(step.to_sym)
  end

  def available_steps(registration = self)
    RegistrationSteps.all_registration_steps.select { |step| send("#{step}_available?", registration) }
  end

  def enabled_steps(registration = self)
    last_step = nil
    disabled = false
    available_steps(registration).select do |step|
      # once we reach one disabled step, all the others should be disabled too
      if disabled
        is_enabled = false
      else
        is_enabled = registration.send("#{step}_enabled?")
        last_step = step
        disabled ||= !is_enabled
      end
      is_enabled
    end
  end

  def completed_steps(registration = self)
    available_steps(registration).select { |step| send("#{step}_completed?", registration) }
  end

  def current_step(registration = self)
    step = (registration.data || {})['current_step']
    return nil unless step.present?
    step.to_sym
  end

  def latest_step(registration = self)
    enabled_steps.last
  end

  def respond_to?(name, include_private = false)
    case name
    when /^(.*)_(available|enabled)\?$/
      return true if RegistrationSteps.is_step?($1)
    end
    super(name, include_private)
  end

  def method_missing(name, *args, &block)
    case name
    when /^(.*)_available\?$/
      return true if RegistrationSteps.is_step?($1)
    when /^(.*)_enabled\?$/
      return prev_step_complete($1) && send("#{$1}_available?") if RegistrationSteps.is_step?($1)
    end
    super(name, *args, &block)
  end

  def prev_step_complete(step, registration = self)
    steps = available_steps(registration)
    index = steps.index(step.to_sym)
    return nil if index.nil?
    
    send("#{steps[index - 1]}_completed?", registration)
  end

  def registration_complete?(registration = self)
    enabled_steps(registration).last == RegistrationSteps.all_registration_steps.last
  end

  def step_after(step, registration = self)
    next_enabled_step(RegistrationSteps.all_registration_steps, step, registration)
  end

  def step_before(step, registration = self)
    next_enabled_step(RegistrationSteps.all_registration_steps.reverse, step, registration)
  end

private

  def next_enabled_step(steps, step, registration = self)
    steps[(steps.find_index(step.to_sym) + 1)..-1].each do |s|
      return s if registration.send("#{s}_enabled?")
    end
    return step
  end
end
