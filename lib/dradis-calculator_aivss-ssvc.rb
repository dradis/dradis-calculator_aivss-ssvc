require 'dradis-plugins'

# Single source of truth. Must run before requiring engine.rb: isolate_namespace
# underscores the module name at require time, so both acronyms need to exist already.
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym('AIVSS')
  inflect.acronym('SSVC')
end

module Dradis
  module Plugins
    module Calculators
      module AIVSSSSVC
      end
    end
  end
end

require 'dradis/plugins/calculators/aivss_ssvc/engine'
require 'dradis/plugins/calculators/aivss_ssvc/version'
