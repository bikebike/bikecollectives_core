$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bikecollectives_core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bikecollectives_core"
  s.version     = BikecollectivesCore::VERSION
  s.authors     = ["Godwin"]
  s.email       = ["goodgodwin@hotmail.com"]
  s.homepage    = "https://bikecollectives.org"
  s.summary     = "Core components shared between bikecollective websites."
  s.description = "Core components shared between bikecollective websites."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency 'rails', '~> 4.2.0'
  s.add_dependency 'pg'
  s.add_dependency 'sass'
  s.add_dependency 'sass-rails'
  s.add_dependency 'haml'
  s.add_dependency 'carrierwave-imageoptimizer'
  s.add_dependency 'carrierwave'
  s.add_dependency 'mini_magick'
  s.add_dependency 'activerecord-session_store'
  s.add_dependency 'sidekiq'
  s.add_dependency 'sass-json-vars'
  s.add_dependency 'premailer-rails'
  s.add_dependency 'redcarpet'
  s.add_dependency 'letter_opener'
  s.add_dependency 'launchy'
  s.add_dependency 'uglifier', '>= 1.3.0'
end
