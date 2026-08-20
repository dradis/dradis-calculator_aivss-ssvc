module Dradis::Plugins::Calculators::AIVSSSSVC
  class Engine < ::Rails::Engine
    isolate_namespace Dradis::Plugins::Calculators::AIVSSSSVC

    include Dradis::Plugins::Base
    provides :addon
    description 'Risk Calculators: AIVSS-SSVC'

    addon_settings :aivss_ssvc do
      settings.default_fields = 'AIVSS-SSVC.Likelihood,AIVSS-SSVC.RiskScore,AIVSS-SSVC.AgentLevel'
    end

    initializer 'calculator_aivss_ssvc.inflections' do
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.acronym('AIVSS')
        inflect.acronym('SSVC')
      end
    end

    initializer 'calculator_aivss_ssvc.asset_precompile_paths' do |app|
      app.config.assets.precompile += [
        'dradis/plugins/calculators/aivss_ssvc/base.css',
        'dradis/plugins/calculators/aivss_ssvc/base.js',
        'dradis/plugins/calculators/aivss_ssvc/manifests/hera.css',
        'dradis/plugins/calculators/aivss_ssvc/manifests/hera.js'
      ]
    end

    initializer 'calculator_aivss_ssvc.mount_engine' do
      Rails.application.routes.append do
        # Enabling/disabling integrations calls Rails.application.reload_routes! we need the enable
        # check inside the block to ensure the routes can be re-enabled without a server restart
        if Engine.enabled?
          mount Engine => '/', as: :aivss_ssvc_calculator
        end
      end
    end
  end
end
