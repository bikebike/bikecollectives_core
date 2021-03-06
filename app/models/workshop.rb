class Workshop < ActiveRecord::Base
  translates :info, :title

  belongs_to :conference
  belongs_to :event_location

  has_many :workshop_facilitators, dependent: :destroy
  has_many :users, through: :workshop_facilitators

  accepts_nested_attributes_for :workshop_facilitators, reject_if: proc { |u| u[:user_id].blank? }, allow_destroy: true

  before_create :make_slug

  def to_param
    slug
  end

  def role(user)
    return nil unless user
    workshop_facilitators.each do |u|
      if u.user_id == user.id
        return conference.registration_exists?(user) ? u.role.to_sym : :unregistered
      end
    end
    return nil
  end

  def facilitator?(user)
    !!role(user)
  end

  def active_facilitators
    users = []
    workshop_facilitators.each do |u|
      users << User.find(u.user_id) unless u.role.to_sym == :requested || u.user_id.nil?
    end
    return users
  end

  def active_facilitator?(user)
    facilitator?(user) && !requested_collaborator?(user)
  end

  def public_facilitator?(user)
    return false if !active_facilitator?(user)
    return true if creator?(user)
    conference.registered?(user)
  end

  def creator?(user)
    role(user) == :creator
  end

  def collaborator?(user)
    role(user) == :collaborator
  end

  def requested_collaborator?(user)
    role(user) == :requested
  end

  def can_edit?(user)
    creator?(user) || collaborator?(user) || conference.host?(user)
  end

  def can_remove?(owner, facilitator)
    # creators cannot be removed
    return false if creator?(facilitator)

    # creator can remove anyone, facilitators can remove themselves
    return creator?(owner) || owner.id == facilitator.id
  end

  def can_delete?(user)
    (creator?(user) && conference.registration_open) || conference.host?(user)
  end

  def can_show_interest?(user)
    return false unless user.present? && !active_facilitator?(user) && conference.registration_open
    registration = conference.registration_for(user)
    return registration.present? && registration.registered?
  end

  def interested?(user)
    can_show_interest?(user) && WorkshopInterest.find_by(workshop_id: id, user_id: user.id)
  end

  def users_by_role(role)
    users = []
    workshop_facilitators.each do |f|
      users << f.user_id if f.role.to_sym == role.to_sym
    end
    return users
  end

  def creator
    users_by_role(:creator).first
  end

  def collaborators
    users_by_role(:collaborator)
  end

  def interested_count
    interested.size
  end

  def interested
    return [] unless id
    return @interested if @interested.present?

    collaborators = []
    workshop_facilitators.each do |f|
      collaborators << f.user_id unless f.role.to_sym == :requested || f.user_id.nil?
    end
    return 10 unless collaborators.present?
    @interested = WorkshopInterest.where("workshop_id=#{id} AND user_id NOT IN (#{collaborators.join ','})") || []
  end

  def can_translate?(user, lang)
    return false unless user.present?
    user.can_translate?(lang, locale) || (can_edit?(user) && lang.to_s != locale.to_s)
  end

  def conference_day
    return nil unless start_time.present? && end_time.present?

    start_day = conference.start_date.change(hour: 0, minute: 0, second: 0)
    w_start_day = start_time.change(hour: 0, minute: 0, second: 0)
    return (((w_start_day - start_day) / 86400) + 1).to_i
  end

  def duration
    return nil unless start_time.present? && end_time.present?
    ((end_time - start_time) / 60).to_i
  end

  def self.all_themes
    [:race_gender, :mechanics, :funding, :organization, :community]
  end

  def self.all_spaces
    [:meeting_room, :workshop, :outdoor_meeting]
  end

  def self.all_needs
    [:sound, :projector, :tools]
  end

  def get_translators(data, loc = nil)
    notify_list = {}
    active_facilitators.each do |facilitator|
      notify_list[facilitator.id] = facilitator
    end
    
    data.each do |column, value|
      (
        loc.present? ? 
        get_translators_for_column_and_locale(column, loc) : 
        get_translators_for_column(column)
      ).each do |id|
        notify_list[id] = User.find(id)
      end
    end
    return notify_list
  end

  def comments
    Comment.for(self)
  end

  def add_comment(user, comment)
    Comment.create_for(self, user, comment)
  end
  
  def validate_block!(workshop_blocks)
    if block.present?
      block_num = block['block'].to_i
      if block['block'].nil? ||
          block_num >= workshop_blocks.length ||
          workshop_blocks[block_num]['days'].index { |b| b.to_s == block['day'].to_s }.nil? ||
          !EventLocation.exists?(event_location_id)
        self.block = nil
        self.event_location_id = nil
        self.save!
      end
    end
  end

  private
    def make_slug
      if !self.slug
        s = self.title.gsub(/[^a-z1-9]+/i, '-').chomp('-').gsub(/\-([A-Z])/, '\1')
        if Organization.find_by(:slug => s) && self.locations && self.locations[0]
          s += '-' + self.locations[0].city
          if Organization.find_by(:slug => s) && locations[0].territory
            s += '-' + self.locations[0].territory
          end
          if Organization.find_by(:slug => s)
            s += '-' + self.locations[0].country
          end
        end
        attempt = 1
        ss = s
        while Organization.find_by(:slug => s)
          attempt += 1
          s = ss + '-' + attempt
        end
        self.slug = s
      end
    end
end
