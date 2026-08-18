# AIVSS-SSVC calculator for Dradis

This addon adds a new page under `/calculators/aivss_ssvc` for you to perform
OWASP AIVSS-SSVC risk calculations, and an **AIVSS-SSVC** tab on every issue so
you can score a finding in place.

AIVSS-SSVC combines the [AIVSS](https://aivss.owasp.org/) agentic-AI capability
model with SSVC-style stakeholder decision making: it computes a numeric risk
score and selects a remediation outcome (Defer, Scheduled, Out-of-Cycle or
Immediate) from a decision matrix built on threat level, agent level and
systemic impact.

The implementation is a port of the reference calculator at
<https://aivss.owasp.org/ssvc.html> and produces identical results for identical
inputs.

The add-on requires [Dradis CE](https://dradis.com/ce/) > 3.0, or
[Dradis Pro](https://dradis.com/).

## Install

Add this to your `Gemfile.plugins`:

    gem 'dradis-calculator_aivss-ssvc'

And

    bundle install

Restart your Dradis server and you should be good to go.

## How the score is calculated

    Likelihood = P(Threat) × P(Vulnerability)
    Risk Score = Likelihood × Exposure × Impact

| Input                                | Options (and value)                                            |
| ------------------------------------ | -------------------------------------------------------------- |
| P(Threat) — exploitation state       | None (0.2), Public PoC (0.5), Active (0.9)                      |
| P(Vulnerability) — exploit success   | Hardened (0.3), Moderate (0.5), Exposed (0.8)                   |
| Impact — systemic consequence        | Contained (2), Significant (5), Critical (10)                   |

Exposure comes from ten capability factors, each scored 1–5 and grouped into
three categories:

| Category                        | Factors                                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------------------- |
| A — Execution Power             | Execution Autonomy, Tool Authority Level, Code Execution Rights, Critical System Access     |
| B — Environment & Adaptation    | Persistent Memory, Dynamic Identity & Permissions, Multi-Agent Coordination                 |
| C — Predictability & Influence  | Self-Modification Capability, Non-Determinism Level, Deceptiveness Potential                |

The three category averages classify the agent, which sets the exposure
multiplier:

* any average ≥ 4.0 → **Prime Mover** (8×)
* otherwise, two or more averages ≥ 3.0 → **Specialist** (4×)
* otherwise, all averages < 2.5 → **Copilot** (2×)
* otherwise (mixed), strongest average ≥ 3.0 → **Specialist** (4×), else **Copilot** (2×)

The remediation outcome is then read off the 3×3×3 decision matrix
(threat level × agent level × impact), not off the numeric score.

## Issue fields

Scoring an issue writes the `AIVSS-SSVC.*` fields listed in
`Dradis::Plugins::Calculators::AivssSsvc::V1::FIELDS` — the three inputs and
their numeric values, the ten capability factors, the three category averages,
the agent level and its exposure multiplier, the likelihood, the risk score,
the outcome, its timeline, and the classification rationale.

There is no vector string in AIVSS-SSVC. When you re-open the calculator on an
issue, the form is rebuilt from those individual fields; anything missing or
unrecognised falls back to the default selection.

## Defaults

Like the reference calculator, the form opens on the AIVSS-SSVC worked example
(Public PoC / Moderate / Critical, with factors 4,4,4,4,3,3,3,2,3,2). Change
`Dradis::Plugins::Calculators::AivssSsvc::V1::DEFAULTS` if you would rather
start somewhere else.

## More information

See the Dradis Framework's [README.md](https://github.com/dradis/dradis-ce/blob/develop/README.md)

## Contributing

See the Dradis Framework's [CONTRIBUTING.md](https://github.com/dradis/dradis-ce/blob/develop/CONTRIBUTING.md)

## License

Dradis Framework and all its components are released under [GNU General Public License version 2.0](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html) as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.

## Feature requests and bugs

Please use the [Dradis Framework issue tracker](https://github.com/dradis/dradis-ce/issues) for add-on improvements and bug reports.
