module Dradis::Plugins::Calculators::AivssSsvc
  class IssuesController < ::IssuesController
    before_action :set_aivss_ssvc_selection, only: :edit

    skip_before_action :remove_unused_state_param

    def edit
      @issue_fields = V1::FIELDS.map do |field|
        value = @issue.fields[field]
        value = 'N/A' if value.blank?
        "#[#{field}]#\n#{value}"
      end.join("\n\n")
    end

    def update
      aivss_ssvc_fields = Hash[
        *params[:aivss_ssvc_fields].to_s.scan(FieldParser::FIELDS_REGEX).flatten.map(&:strip)
      ]

      aivss_ssvc_fields.each do |name, value|
        @issue.set_field(name, value)
      end

      if @issue.save
        redirect_to main_app.project_issue_path(current_project, @issue), notice: 'AIVSS-SSVC fields updated.'
      else
        render :edit
      end
    end

    private

    # There is no vector string in AIVSS-SSVC, so the state of the form is
    # rebuilt out of the issue's individual fields.
    def set_aivss_ssvc_selection
      @aivss_ssvc_selection = V1.selection_from_fields(@issue.fields)
    end
  end
end
