module BikecollectivesCore
  class Engine < ::Rails::Engine
    # isolate_namespace BikecollectivesCore
  end
end

module ActiveRecord
  class PremissionDenied < RuntimeError
  end
end
