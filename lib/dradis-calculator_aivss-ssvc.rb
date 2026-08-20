require 'dradis-plugins'

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
