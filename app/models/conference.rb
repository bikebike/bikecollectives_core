class Conference < ActiveRecord::Base
  translates :info, :title, :payment_message, :group_ride_info, :housing_info, :workshop_info, :schedule_info, :travel_info, :city_info, :what_to_bring, :volunteering_info, :additional_details

  mount_uploader :cover, CoverUploader
  mount_uploader :poster, PosterUploader

  belongs_to :conference_type
  belongs_to :city

  has_many :conference_host_organizations, dependent: :destroy
  has_many :organizations, through: :conference_host_organizations
  has_many :conference_administrators, dependent: :destroy
  has_many :administrators, through: :conference_administrators, source: :user
  has_many :event_locations  
  has_many :workshops

  accepts_nested_attributes_for :conference_host_organizations, reject_if: proc {|u| u[:organization_id].blank?}, allow_destroy: true

  before_create :make_slug, :make_title

  def to_param
    slug
  end

  def host_organization?(org)
    return false unless org.present?
    org_id = org.is_a?(Organization) ? org.id : org

    organizations.each do |o|
      return true if o.id = org_id
    end

    return false
  end

  def host?(user)
    if user.present?
      return true if user.administrator?
      
      conference_administrators.each do |u|
        return true if user.id == u.user_id
      end
    end
    return false
  end

  def url(action = :show)
    path(action)
  end

  def path(action = :show)
    action = action.to_sym
    '/conferences/' + conference_type.slug + '/' + slug + (action == :show ? '' : '/' + action.to_s)
  end

  def location
    return nil unless organizations.present?
    organizations.first.location
  end

  def registered?(user)
    return false if user.nil?
    registration = registration_for(user)
    return registration ? registration.attending? : false
  end

  def registration_exists?(user)
    registration_for(user).present?
  end

  def registration_open
    registration_status == :open
  end

  def can_register?(user = nil)
    registration_status == :open || registration_status == :pre || registered?(user)
  end

  def registration_status
    s = read_attribute(:registration_status)
    s.present? ? s.to_sym : nil
  end

  def registration_status=(new_registration_status)
    write_attribute :registration_status, new_registration_status.to_s
  end

  def make_slug(reset = false)
    if reset
      self.slug = nil
    end

    self.slug ||= Conference.generate_slug(
        conferencetype || :annual,
        conference_year,
        city_name.gsub(/\s/, '')
      )
  end

  def make_title(reset = false)
    if reset
      self.title = nil
    end

    self.title ||= Conference.generate_title(
        conferencetype || :annual,
        conference_year,
        city_name.gsub(/\s/, '')
      )
  end

  def city_name
    return city.city if city.present?
    return location.present? ? location.city : nil
  end

  def conference_year
    self.year || (end_date.present? ? end_date.year : nil)
  end

  def over?
    return false unless end_date.present?
    return end_date < DateTime.now
  end

  def min_arrival_date
    return nil unless start_date.present?
    return start_date - 7.days
  end

  def max_departure_date
    return nil unless end_date.present?
    return end_date + 7.days
  end

  def registration_for(user)
    user = user.id if user.is_a?(User)
    @registration_cache ||= {}
    @registration_cache[user] ||= ConferenceRegistration.where(conference_id: id, user_id: user).first
    return @registration_cache[user]
  end

  def default_currency
    city.country == 'CA' ? :CAD : :USD
  end

  def self.default_payment_amounts
    [25, 50, 100]
  end

  def self.default_currencies
    [:USD, :CAD]
  end

  def self.conference_types
    {
      annual: { slug: '%{city}%{year}',   title: 'Bike!Bike! %{year}'},
      n:      { slug: 'North%{year}',     title: 'Bike!Bike! North %{year}'},
      s:      { slug: 'South%{year}',     title: 'Bike!Bike! South %{year}'},
      e:      { slug: 'East%{year}',      title: 'Bike!Bike! East %{year}'},
      w:      { slug: 'West%{year}',      title: 'Bike!Bike! West %{year}'},
      ne:     { slug: 'Northeast%{year}', title: 'Bike!Bike! Northeast %{year}'},
      nw:     { slug: 'Northwest%{year}', title: 'Bike!Bike! Northwest %{year}'},
      se:     { slug: 'Southeast%{year}', title: 'Bike!Bike! Southeast %{year}'},
      sw:     { slug: 'Southwest%{year}', title: 'Bike!Bike! Southwest %{year}'}
    }
  end

  def self.generate_slug(type, year, city)
    Conference.conference_types[(type || :annual).to_sym][:slug].gsub('%{city}', city).gsub('%{year}', year.to_s)
  end

  def self.generate_title(type, year, city)
    Conference.conference_types[(type || :annual).to_sym][:title].gsub('%{city}', city).gsub('%{year}', year.to_s)
  end

  def self.default_provider_conditions
    { 'distance' => { 'number' => 0, 'unit' => 'mi' }}
  end

  def copy_data
    {
      workshop_info: { show: workshop_info.present?, value: workshop_info, heading: 'articles.conferences.headings.workshop_info' },
      housing_info: { show: housing_info.present?, value: housing_info, heading: 'articles.conferences.headings.housing_info' },
      group_ride_info: { show: group_ride_info.present?, value: group_ride_info, heading: 'articles.conferences.headings.group_ride_info' },
      payment_message: { show: payment_message.present?, value: payment_message, heading: 'articles.conferences.headings.payment_message' },
      schedule_info: { show: schedule_info.present?, value: schedule_info, heading: 'articles.conferences.headings.schedule_info' },
      travel_info: { show: travel_info.present?, value: travel_info, heading: 'articles.conferences.headings.travel_info', vars: { city: city.city } },
      city_info: { show: city_info.present?, value: city_info, heading: 'articles.conferences.headings.city_info', vars: { city: city.city } },
      what_to_bring: { show: what_to_bring.present?, value: what_to_bring, heading: 'articles.conferences.headings.what_to_bring' },
      volunteering_info: { show: volunteering_info.present?, value: volunteering_info, heading: 'articles.conferences.headings.volunteering_info' },
      additional_details: { show: additional_details.present?, value: additional_details, heading: false },
      workshops: { show: false },
      schedule: { show: false }
    }
  end

  def front_page_details
    [
      :workshop_info,
      :schedule
    ]
  end

  def extended_details
    [
      :payment_message,
      :housing_info,
      :workshop_info,
      :schedule_info,
      :group_ride_info,
      :city_info,
      :travel_info,
      :what_to_bring,
      :volunteering_info,
      :additional_details,
      :workshops,
      :schedule
    ]
  end

  def post_conference_survey_questions
    # numerical = (1..5)
    # agreement = [:strongly_agree, :agree, :neither, :disagree, :strongly_disagree]
    satisfaction = [:very_unsatisfied, :unsatisfied, :neutral, :satisfied, :very_satisfied]
    likelihood = [:not_likely, :likely, :very_likely]
    {
      years_attended:    { type: :likert, options: [:first, :two_to_four, :five_or_more] },
      reattend_again:    { type: :likert, options: likelihood },
      services:          { type: :multi_likert, options: satisfaction, waive_option: :na, comment: true, questions: [
          :housing,
          :bike,
          :food,
          :schedule,
          :events,
          :workshops,
          :website] },
      experience:        { type: :open_ended, comment_size: :small },
      improvement_ideas: { type: :open_ended },
      comments:          { type: :open_ended }
    }
  end

  def post_conference_survey_version
    slug
  end

  def post_conference_survey_available?(user = nil)
    is_public && !registration_open && (user.nil? || (user.is_a?(ConferenceRegistration) ? user : registration_for(user)).checked_in?)
  end

  def post_conference_survey_name
    :post_conference
  end

  def schedule_interval
    0.25
  end

  def validate_workshop_blocks
    workshops.each do |workshop|
      workshop.validate_block!(workshop_blocks)
    end
  end
end
