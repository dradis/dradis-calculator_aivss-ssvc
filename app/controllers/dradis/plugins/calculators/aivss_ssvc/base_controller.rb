module Dradis::Plugins::Calculators::AivssSsvc
  class BaseController < ActionController::Base
    def index
      @aivss_ssvc_selection = V1::DEFAULTS
      @issue_fields = V1::FIELDS.map { |field| "#[#{field}]#\nN/A" }.join("\n\n")
    end
  end
end
