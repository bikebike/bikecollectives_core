require 'geocoder'
require 'geocoder/railtie'
require 'geocoder/calculations'

Geocoder::Railtie.insert

class CityCache < ActiveRecord::Base
  self.table_name = :city_cache

  belongs_to :city

  # look for a term to see if its already been searched for
  def self.search(str)
    CityCache.find_by_search(normalize_string(str))
  end

  # cache this search term
  def self.cache(str, city_id)
  	CityCache.create(city_id: city_id, search: normalize_string(str))
  end
  
  def self.cache_enabled_search(str, &block)
    return yield unless Rails.env.test?

    # we make a lot of calls to the Geocoder during tests, this takes extra time but more importantly we sometimes max out our calls
    # so we'll cache the results and allow them to be checked in to minimize on this
    file = File.expand_path('./features/support/location_cache.json')
    begin
      test_cache = JSON.parse(File.read(file)) if File.exist?(file)
    rescue; end

    test_cache ||= {}
    
    # return the cached verion if we have it
    return Geocoder::Result::Google.new(test_cache[str]) if test_cache[str].present?

    # otherwise store the search in the cache
    result = yield

    # store it
    if result.present?
      test_cache[str] = result.data
      puts test_cache
      File.open(file, 'w+') { |f| f.write(test_cache.to_json) }
    end

    return result
  end

  private
    def self.normalize_string(str)
      # remove accents, unnecessary whitespace, punctuation, and lowcase tje string
      I18n.transliterate(str).gsub(/[^\w\s]/, '').gsub(/\s\s+/, ' ').strip.downcase
    end
end
