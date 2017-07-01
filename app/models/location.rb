class Location < ActiveRecord::Base
  has_many :locations_organization
  has_many :organizations, through: :locations_organization

  geocoded_by :full_address

  belongs_to :city

  reverse_geocoded_by :latitude, :longitude, address: :full_address
  after_validation :geocode, if: ->(obj){ obj.country_changed? or obj.territory_changed? or obj.city_changed? or obj.street_changed? or obj.postal_code_changed? or obj.latitude.blank? or obj.longitude.blank? }

  def full_address
    ([street, [city.city, city.territory].compact.join(' '), [city.country, postal_code].compact.join(' ')] - [nil, '']).join(', ')
  end

  def territory
    city.territory
  end

  def country
    city.country
  end

  def slugify
    [I18n.transliterate(city).strip.gsub(' ', '-').gsub(/[^\w-]/, ''), territory, country].compact.join('_').downcase
  end

  def translate_territory
    # territories aren't always available so return NIL if we don't have a translation
    I18n.t("geography.subregions.#{country}.#{territory}", resolve: false)
  end

  def translate_country
    I18n.t("geography.countries.#{country}")
  end

  def mailing_address
    [
      street,
      "#{city.city}, #{translate_territory || territory}",
      "#{translate_country} #{postal_code}"
    ].join("\n")
  end

  def self.from_city_address(address, city)
    return nil unless city.present?
    location = Geocoder.search("#{address}, #{city.to_s}", language: 'en').first
    return nil unless location.present? && location.data.present?
    Location.new(
        city_id: city.id,
        street: address,
        postal_code: Location.search_data(location.data, 'postal_code'),
        latitude: location.data['geometry']['location']['lat'],
        longitude: location.data['geometry']['location']['lng']
      )
  end

  def self.search_data(data, key)
    data['address_components'].each do |component|
      return component['long_name'] || component['short_name'] if component['types'].include?(key.to_s)
    end
    return nil
  end

end
