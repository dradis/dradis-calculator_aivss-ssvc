document.addEventListener('turbo:load', () => {
  const root = document.querySelector('[data-behavior~=aivss-ssvc-calc]');
  if (!root) return;

  const config = JSON.parse(root.dataset.aivssSsvcConfig);
  const OUTCOME_MATRIX = config.outcomeMatrix;
  const TIMELINE_BY_OUTCOME = config.timelineByOutcome;
  const BADGE_CLASS = config.badgeClass;

  class AIVSSSSVCCalculator {
    constructor(root) {
      this.root = root;
      this.inputs = {};
      root.querySelectorAll('[data-behavior~=aivss-ssvc-input]').forEach((select) => {
        this.inputs[select.dataset.input] = select;
      });

      this.factors = Array.from(root.querySelectorAll('[data-behavior~=aivss-ssvc-factor]'));
      this.choices = Array.from(root.querySelectorAll('[data-behavior~=aivss-ssvc-choice]'));
      this.fieldSwitches = Array.from(root.querySelectorAll('[data-behavior~=aivss-ssvc-field-switch]'));
      this.result = root.querySelector('[data-behavior~=aivss-ssvc-result]');
      this.fieldsUrl = root.dataset.aivssSsvcFieldsUrl;
      this.fieldRequestId = 0;
      this.values = {};
    }

    init() {
      this.choices.forEach((choice) => {
        choice.addEventListener('click', () => {
          this.selectChoice(choice);
          this.calculate();
        });
      });

      this.fieldSwitches.forEach((fieldSwitch) => {
        fieldSwitch.addEventListener('change', () => this.writeResult());
      });

      this.bindFieldSelection('aivss-ssvc-select-all', true);
      this.bindFieldSelection('aivss-ssvc-select-none', false);
      this.calculate();
    }

    bindFieldSelection(behavior, checked) {
      const control = this.root.querySelector(`[data-behavior~=${behavior}]`);
      if (!control) return;

      control.addEventListener('click', (event) => {
        event.preventDefault();
        this.fieldSwitches.forEach((fieldSwitch) => {
          fieldSwitch.checked = checked;
        });
        this.writeResult();
      });
    }

    // ------------------------------------------------ ported from the web app
    avg(numbers) {
      return numbers.length ? numbers.reduce((a, b) => a + b, 0) / numbers.length : 0;
    }

    round2(value) {
      return Math.round(value * 100) / 100;
    }

    classifyAgent(aAvg, bAvg, cAvg) {
      const anyGE4 = aAvg >= 4.0 || bAvg >= 4.0 || cAvg >= 4.0;
      const countGE3 = (aAvg >= 3.0) + (bAvg >= 3.0) + (cAvg >= 3.0);
      const allLT25 = aAvg < 2.5 && bAvg < 2.5 && cAvg < 2.5;

      if (anyGE4) {
        return {
          key: 'primemover', label: 'Prime Mover', exposure: 8,
          rationale: 'At least one category average is ≥ 4.0, indicating high capability on a harm-driving dimension.'
        };
      }
      if (countGE3 >= 2) {
        return {
          key: 'specialist', label: 'Specialist', exposure: 4,
          rationale: 'At least two category averages are ≥ 3.0, indicating broad moderate capability across multiple dimensions.'
        };
      }
      if (allLT25) {
        return {
          key: 'copilot', label: 'Copilot', exposure: 2,
          rationale: 'All category averages are < 2.5, indicating constrained capability across execution, adaptation, and influence.'
        };
      }

      const strongest = Math.max(aAvg, bAvg, cAvg);
      if (strongest >= 3.0) {
        return {
          key: 'specialist', label: 'Specialist', exposure: 4,
          rationale: 'The mixed profile has a strongest category average ≥ 3.0. The higher classification applies.'
        };
      }
      return {
        key: 'copilot', label: 'Copilot', exposure: 2,
        rationale: 'The mixed profile has a strongest category average < 3.0. The Copilot classification applies.'
      };
    }

    computeOutcome(threatKey, agentKey, impactKey) {
      return OUTCOME_MATRIX?.[threatKey]?.[agentKey]?.[impactKey] || 'Scheduled';
    }
    // ----------------------------------------------- /ported from the web app

    selectChoice(choice) {
      const target = this.root.querySelector(`#${choice.dataset.selectTarget}`);
      if (!target) return;

      this.root.querySelectorAll(`[data-select-target="${choice.dataset.selectTarget}"]`).forEach((button) => {
        button.classList.remove('active', 'btn-primary');
        button.setAttribute('aria-pressed', 'false');
      });
      choice.classList.add('active', 'btn-primary');
      choice.setAttribute('aria-pressed', 'true');
      target.value = choice.value;
    }

    selectedOption(input) {
      return this.root.querySelector(`[data-select-target="${input.id}"].active`);
    }

    categoryAverage(category) {
      const scores = this.factors
        .filter((factor) => factor.dataset.category === category)
        .map((factor) => {
          const value = Number(factor.value);
          return Number.isFinite(value) ? value : 1;
        });

      return this.avg(scores);
    }

    // querySelectorAll, not querySelector: on the issue view the score and the
    // outcome are echoed in the Result pill as well as in the results panel.
    setText(behavior, text) {
      this.root.querySelectorAll(`[data-behavior~=${behavior}]`).forEach((element) => {
        element.textContent = text;
      });
    }

    calculate() {
      const threatSelect = this.inputs.threat;
      const vulnSelect = this.inputs.vulnerability;
      const impactSelect = this.inputs.impact;

      const threatOption = this.selectedOption(threatSelect);
      const vulnOption = this.selectedOption(vulnSelect);
      const impactOption = this.selectedOption(impactSelect);

      const pThreat = Number(threatOption.dataset.score);
      const pVuln = Number(vulnOption.dataset.score);
      const impactValue = Number(impactOption.dataset.score);

      const aAvg = this.categoryAverage('A');
      const bAvg = this.categoryAverage('B');
      const cAvg = this.categoryAverage('C');

      const agent = this.classifyAgent(aAvg, bAvg, cAvg);

      const likelihood = pThreat * pVuln;
      const riskScore = likelihood * agent.exposure * impactValue;
      const outcome = this.computeOutcome(threatSelect.value, agent.key, impactSelect.value);

      const state = {
        agent, aAvg, bAvg, cAvg, likelihood, riskScore, outcome,
        pThreat, pVuln, impactValue, threatOption, vulnOption, impactOption
      };

      this.render(state);
      this.writeFields(state);
    }

    render(state) {
      this.setText('aivss-ssvc-likelihood', String(this.round2(state.likelihood)));
      this.setText('aivss-ssvc-likelihood-mini', `P(Threat) ${state.pThreat} × P(Vulnerability) ${state.pVuln}`);

      this.setText('aivss-ssvc-risk-score', String(this.round2(state.riskScore)));
      this.setText('aivss-ssvc-risk-mini', `${this.round2(state.likelihood)} × ${state.agent.exposure} × ${state.impactValue}`);

      this.setText('aivss-ssvc-agent-level', state.agent.label);
      this.setText('aivss-ssvc-agent-mini', `Exposure multiplier: ${state.agent.exposure}×`);

      this.setText('aivss-ssvc-averages', `${this.round2(state.aAvg)} / ${this.round2(state.bAvg)} / ${this.round2(state.cAvg)}`);

      const badge = this.root.querySelector('[data-behavior~=aivss-ssvc-outcome]');
      if (badge) {
        badge.className = `aivss-ssvc-badge ${BADGE_CLASS[state.outcome] || ''}`;
        badge.textContent = state.outcome;
      }

      this.setText(
        'aivss-ssvc-rationale',
        `Decision inputs: Threat=${state.threatOption.textContent.trim()}, Agent=${state.agent.label} (${state.agent.exposure}×), ` +
        `Impact=${state.impactOption.textContent.trim()}. Classification rationale: ${state.agent.rationale}`
      );

      this.setText('aivss-ssvc-outcome-text', state.outcome);
      this.setText('aivss-ssvc-timeline', TIMELINE_BY_OUTCOME[state.outcome] || '');
    }

    async writeResult() {
      if (!this.result || !this.fieldsUrl) return;

      const fields = this.fieldSwitches.length
        ? this.fieldSwitches.filter((fieldSwitch) => fieldSwitch.checked).map((fieldSwitch) => fieldSwitch.dataset.fieldName)
        : Object.keys(this.values);
      const requestId = ++this.fieldRequestId;
      const csrfToken = document.querySelector('meta[name=csrf-token]')?.content;

      const response = await fetch(this.fieldsUrl, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          'Accept': 'text/plain',
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ fields, values: this.values })
      });

      if (response.ok) {
        const output = await response.text();
        if (requestId === this.fieldRequestId) this.result.value = output;
      }
    }

    writeFields(state) {
      if (!this.result) return;

      const values = {};

      values[this.inputs.threat.dataset.field] = state.threatOption.dataset.label;
      values[this.inputs.threat.dataset.valueField] = state.pThreat;
      values[this.inputs.vulnerability.dataset.field] = state.vulnOption.dataset.label;
      values[this.inputs.vulnerability.dataset.valueField] = state.pVuln;
      values[this.inputs.impact.dataset.field] = state.impactOption.dataset.label;
      values[this.inputs.impact.dataset.valueField] = state.impactValue;

      this.factors.forEach((factor) => {
        values[factor.dataset.field] = factor.value;
      });

      values['AIVSS-SSVC.CategoryA'] = this.round2(state.aAvg);
      values['AIVSS-SSVC.CategoryB'] = this.round2(state.bAvg);
      values['AIVSS-SSVC.CategoryC'] = this.round2(state.cAvg);
      values['AIVSS-SSVC.AgentLevel'] = state.agent.label;
      values['AIVSS-SSVC.ExposureMultiplier'] = state.agent.exposure;
      values['AIVSS-SSVC.Likelihood'] = this.round2(state.likelihood);
      values['AIVSS-SSVC.RiskScore'] = this.round2(state.riskScore);
      values['AIVSS-SSVC.Outcome'] = state.outcome;
      values['AIVSS-SSVC.Timeline'] = TIMELINE_BY_OUTCOME[state.outcome];
      values['AIVSS-SSVC.Rationale'] = state.agent.rationale;

      this.values = values;

      this.root.querySelectorAll('[data-behavior~=aivss-ssvc-field-value]').forEach((element) => {
        element.textContent = values[element.dataset.fieldName];
      });

      this.writeResult();
    }
  }

  new AIVSSSSVCCalculator(root).init();
});
