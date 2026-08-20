module Dradis::Plugins::Calculators::AIVSSSSVC
  class IssuesController < ::IssuesController
    before_action :set_aivss_ssvc_selection, :set_aivss_ssvc_field_groups, only: :edit

    skip_before_action :remove_unused_state_param

    def edit
      @issue_fields = V1.field_output(@issue.fields)
    end

    def update
      aivss_ssvc_fields = Hash[
        *params[:aivss_ssvc_fields].to_s.scan(FieldParser::FIELDS_REGEX).flatten.map(&:strip)
      ]

      aivss_ssvc_fields.each do |name, value|
        @issue.set_field(name, value)
      end

      existing_fields = @issue.fields.keys & V1::FIELDS
      (existing_fields - aivss_ssvc_fields.keys).each do |name|
        @issue.delete_field(name)
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

    def set_aivss_ssvc_field_groups
      existing_fields = @issue.fields.keys.select { |field| field.start_with?('AIVSS-SSVC.') }
      default_fields = Engine.settings.fields.split(',').map(&:strip) & V1::FIELDS
      @enabled_fields = existing_fields.any? ? existing_fields : default_fields

      grouped_fields = V1::FIELDS.group_by do |field|
        name = field.delete_prefix('AIVSS-SSVC.')

        if %w[Threat Threat.Value Vulnerability Vulnerability.Value Impact Impact.Value].include?(name)
          'Inputs'
        elsif V1::FACTORS.any? { |factor| factor[:field] == name }
          'Capability Factors'
        else
          'Calculated Results'
        end
      end

      calculated_fields = grouped_fields.fetch('Calculated Results')
      default_calculated_fields = default_fields & calculated_fields
      grouped_fields['Calculated Results'] = default_calculated_fields + (calculated_fields - default_calculated_fields)

      @aivss_ssvc_field_groups = [
        'Calculated Results',
        'Inputs',
        'Capability Factors'
      ].index_with { |group_name| grouped_fields.fetch(group_name) }
    end
  end
end
