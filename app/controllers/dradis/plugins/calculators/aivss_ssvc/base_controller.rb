module Dradis::Plugins::Calculators::AIVSSSSVC
  class BaseController < ActionController::Base
    def index
      @aivss_ssvc_selection = V1::DEFAULTS
      @issue_fields = V1.field_output
    end

    def fields
      render plain: V1.field_output(aivss_ssvc_values_params, fields: requested_fields)
    end

    private

    def aivss_ssvc_values_params
      params.fetch(:values, {}).permit(*V1::FIELDS).to_h
    end

    def requested_fields
      Array(params.fetch(:fields, V1::FIELDS))
    end
  end
end
