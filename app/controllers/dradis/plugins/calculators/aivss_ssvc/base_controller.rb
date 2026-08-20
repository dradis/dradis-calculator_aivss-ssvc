module Dradis::Plugins::Calculators::AIVSSSSVC
  class BaseController < ActionController::Base
    def index
      @aivss_ssvc_selection = V1::DEFAULTS
      @issue_fields = V1.field_output
    end

    def fields
      values = params.fetch(:values, {}).permit(*V1::FIELDS).to_h
      fields = Array(params.fetch(:fields, V1::FIELDS))

      render plain: V1.field_output(values, fields: fields)
    end
  end
end
