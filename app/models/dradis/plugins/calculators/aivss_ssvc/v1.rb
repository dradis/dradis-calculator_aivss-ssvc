module Dradis::Plugins::Calculators::AIVSSSSVC
  # Definitions for the OWASP AIVSS-SSVC calculator.
  #
  # Every constant below (probabilities, impact values, capability factors and
  # the default selection) is taken verbatim from https://aivss.owasp.org/ssvc.html
  # so that a finding scored in Dradis produces the same numbers and the same
  # remediation outcome as the same finding scored on the web version.
  #
  # The decision matrix itself lives in the JS calculator, which is what
  # evaluates it in the browser.
  class V1
    THREAT_LEVELS = [
      { key: 'none',   label: 'None',       value: 0.2, description: 'No evidence of exploitation or public proof of concept.' },
      { key: 'poc',    label: 'Public PoC', value: 0.5, description: 'A public proof of concept or known exploitation method exists.' },
      { key: 'active', label: 'Active',     value: 0.9, description: 'Reliable exploitation occurs in the wild.' }
    ].freeze

    VULNERABILITY_POSTURES = [
      { key: 'hardened', label: 'Hardened', value: 0.3, description: 'Strong controls make successful exploitation less likely.' },
      { key: 'moderate', label: 'Moderate', value: 0.5, description: 'Some controls limit exploitation, but meaningful exposure remains.' },
      { key: 'exposed',  label: 'Exposed',  value: 0.8, description: 'Limited controls make successful exploitation more likely.' }
    ].freeze

    IMPACT_LEVELS = [
      { key: 'contained',   label: 'Contained',   value: 2,  description: 'The effect has a limited blast radius.' },
      { key: 'significant', label: 'Significant', value: 5,  description: 'The effect disrupts a major business function.' },
      { key: 'critical',    label: 'Critical',    value: 10, description: 'The effect threatens safety or the organization.' }
    ].freeze

    INPUTS = [
      {
        id: 'threat',
        field: 'AIVSS-SSVC.Threat',
        value_field: 'AIVSS-SSVC.Threat.Value',
        label: 'P(Threat): exploitation state',
        options: THREAT_LEVELS
      },
      {
        id: 'vulnerability',
        field: 'AIVSS-SSVC.Vulnerability',
        value_field: 'AIVSS-SSVC.Vulnerability.Value',
        label: 'P(Vulnerability): exploit success probability',
        options: VULNERABILITY_POSTURES
      },
      {
        id: 'impact',
        field: 'AIVSS-SSVC.Impact',
        value_field: 'AIVSS-SSVC.Impact.Value',
        label: 'Impact: systemic consequence',
        options: IMPACT_LEVELS
      }
    ].freeze

    CATEGORIES = {
      'A' => 'A: Execution Power',
      'B' => 'B: Environment & Adaptation',
      'C' => 'C: Predictability & Influence'
    }.freeze

    FACTORS = [
      { id: 'f1',  field: 'ExecutionAutonomy',      category: 'A', name: 'Execution Autonomy',             description: 'Degree of independent operation without human approval.' },
      { id: 'f2',  field: 'ToolAuthorityLevel',     category: 'A', name: 'Tool Authority Level',           description: 'Power and scope of tools the agent can invoke.' },
      { id: 'f3',  field: 'CodeExecutionRights',    category: 'A', name: 'Code Execution Rights',          description: 'Ability to execute, generate, or modify code.' },
      { id: 'f4',  field: 'CriticalSystemAccess',   category: 'A', name: 'Critical System Access',         description: 'Direct access to production, financial, or safety-critical systems.' },
      { id: 'f5',  field: 'PersistentMemory',       category: 'B', name: 'Persistent Memory',              description: 'Ability to store and recall information across sessions.' },
      { id: 'f6',  field: 'DynamicIdentity',        category: 'B', name: 'Dynamic Identity & Permissions', description: 'Ability to assume roles or elevate privileges.' },
      { id: 'f7',  field: 'MultiAgentCoordination', category: 'B', name: 'Multi-Agent Coordination',       description: 'Ability to orchestrate or interact with other agents.' },
      { id: 'f8',  field: 'SelfModification',       category: 'C', name: 'Self-Modification Capability',   description: 'Ability to alter logic, goals, or behavior.' },
      { id: 'f9',  field: 'NonDeterminism',         category: 'C', name: 'Non-Determinism Level',          description: 'Variability and unpredictability in decision-making.' },
      { id: 'f10', field: 'Deceptiveness',          category: 'C', name: 'Deceptiveness Potential',        description: 'Capacity to mislead or obfuscate intentions/actions.' }
    ].freeze

    # The state the web version loads with. Issues that already carry
    # AIVSS-SSVC fields override this on a field-by-field basis, see
    # .selection_from_fields below.
    DEFAULTS = {
      'threat'        => 'poc',
      'vulnerability' => 'moderate',
      'impact'        => 'critical',
      'factors'       => {
        'f1' => 4, 'f2' => 4, 'f3' => 4, 'f4' => 4, 'f5' => 3,
        'f6' => 3, 'f7' => 3, 'f8' => 2, 'f9' => 3, 'f10' => 2
      }.freeze
    }.freeze

    FIELD_NAMES = %i[
      Threat
      Threat.Value
      Vulnerability
      Vulnerability.Value
      Impact
      Impact.Value
      ExecutionAutonomy
      ToolAuthorityLevel
      CodeExecutionRights
      CriticalSystemAccess
      PersistentMemory
      DynamicIdentity
      MultiAgentCoordination
      SelfModification
      NonDeterminism
      Deceptiveness
      CategoryA
      CategoryB
      CategoryC
      AgentLevel
      ExposureMultiplier
      Likelihood
      RiskScore
      Outcome
      Timeline
      Rationale
    ].freeze

    FIELDS = FIELD_NAMES.map { |name| "AIVSS-SSVC.#{name}".freeze }.freeze

    # Rebuilds the state of the form out of the issue's individual AIVSS-SSVC
    # fields. Anything missing or unrecognised falls back to DEFAULTS, so a
    # partially scored issue still opens on a usable form.
    def self.selection_from_fields(issue_fields = {})
      issue_fields ||= {}

      selection = { 'factors' => {} }

      INPUTS.each do |input|
        selection[input[:id]] =
          key_for(input[:options], issue_fields[input[:field]]) || DEFAULTS[input[:id]]
      end

      FACTORS.each do |factor|
        score = issue_fields["AIVSS-SSVC.#{factor[:field]}"].to_s.strip[/\A[1-5]\z/]
        selection['factors'][factor[:id]] = (score || DEFAULTS['factors'][factor[:id]]).to_i
      end

      selection
    end

    # Accepts either the stored label ('Public PoC') or the internal key ('poc').
    def self.key_for(options, value)
      return nil if value.blank?

      value = value.to_s.strip
      option = options.find { |o| o[:key].casecmp(value).zero? || o[:label].casecmp(value).zero? }
      option && option[:key]
    end
    private_class_method :key_for
  end
end
