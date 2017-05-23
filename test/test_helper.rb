# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# turn off warnings
$VERBOSE = nil

require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../../db/migrate', __FILE__)
require "rails/test_help"

require 'yaml'

def setup_db
  # set up the database
  DatabaseCleaner.clean_with :truncation
  YAML::load_file('test/data.yml').each do |model_name, data|
    model_class = Object.const_get(model_name.classify)
    data.each do |model_data|
      model_class.create(model_data)
    end
  end
end

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end
