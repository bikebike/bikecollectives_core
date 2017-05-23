class User < ActiveRecord::Base
  authenticates_with_sorcery! do |config|
        config.authentications_class = Authentication
    end

  validates :email, uniqueness: true

  mount_uploader :avatar, AvatarUploader

  has_many :user_organization_relationships
  has_many :organizations, through: :user_organization_relationships
  has_many :conferences, through: :conference_administrators
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  before_update do |user|
    user.locale ||= I18n.locale
    user.email.downcase! if user.email.present?
  end

  before_save do |user|
    user.locale ||= I18n.locale
    user.email.downcase! if user.email.present?
  end

  def can_translate?(to_locale = nil, from_locale = nil)
    is_translator unless to_locale.present?

    from_locale = I18n.locale unless from_locale.present?
    return languages.present? &&
      to_locale.to_s != from_locale.to_s &&
      languages.include?(to_locale.to_s) &&
      languages.include?(from_locale.to_s)
  end

  def name
    firstname || username || email
  end

  def named_email
    name = firstname || username
    return email unless name
    return "#{name} <#{email}>"
  end

  def administrator?
    role == 'administrator'
  end

  def following_page?(application_id, group = nil, page = nil, index = nil, variant = nil, search_parents = false)
    following = PageFollower.where(user_id: id, application_id: application_id, group: group || '-', page: page || '-', index: index, variant: variant).present?
    return following unless search_parents
    return following ||
      PageFollower.where(user_id: id, application_id: application_id, group: group, page: '-').present? ||
      PageFollower.where(user_id: id, application_id: application_id, group: '-', page: '-').present?
  end

  def follow_page(application_id, group, page, index, variant)
    unless following_page?(application_id, group, page, index, variant, false)
      PageFollower.create(user_id: id, application_id: application_id, group: group || '-', page: page || '-', index: index, variant: variant)
    end
  end

  def unfollow_page(application_id, group, page, index, variant)
    PageFollower.where(user_id: id, application_id: application_id, group: group || '-', page: page || '-', index: index, variant: variant).destroy_all
  end

  def following_translation?(application_id, key)
    TranslationFollower.where(user_id: id, application_id: application_id, key: key).present?
  end

  def follow_translation(application_id, key)
    unless following_translation?(application_id, key)
      TranslationFollower.create(user_id: id, application_id: application_id, key: key)
    end
  end

  def unfollow_translation(application_id, key)
    TranslationFollower.where(user_id: id, application_id: application_id, key: key).destroy_all
  end

  def following_locale?(application_id, locale)
    LocaleFollower.where(user_id: id, application_id: application_id, locale: locale).present?
  end

  def follow_locale(application_id, locale)
    unless following_locale?(application_id, locale)
      LocaleFollower.create(user_id: id, application_id: application_id, locale: locale)
    end
  end

  def unfollow_locale(application_id, locale)
    LocaleFollower.where(user_id: id, application_id: application_id, locale: locale).destroy_all
  end

  def self.AVAILABLE_LANGUAGES
    (I18n.respond_to?(:enabled_locales) ? I18n.enabled_locales : [:en, :es, :fr]) + [:ar]
  end

  def self.get(email)
    find_user(email) || create(email: email, locale: I18n.locale)
  end

  def self.find_user(email)
    User.where('lower(email) = ?', email.downcase).first
  end

end
