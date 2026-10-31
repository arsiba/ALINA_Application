# ALINA – LLM Privacy Awareness Assessment

**ALINA** is a research application developed as part of the bachelor's thesis:

**The Awareness-Gap in LLMs: Design, Entwicklung und Evaluierung einer Softwareanwendung zur Messung des Nutzerbewusstseins über implizit abgeleitete personenbezogene Daten aus LLM-Interaktionen**

The name **ALINA** is derived from the thesis title:

**A**wareness-Gap in **L**LMs: Design, Entwicklung und Evaluierung einer Softwareanwendung zur Messung des Nutzerbewusstseins über **I**mplizit abgeleitete personenbezogene Date**N** aus LLM-Inter**A**ktionen.

## About

ALINA aims to measure the gap between users' awareness of what Large Language Models (LLMs) can infer about them and the personal information these models can actually derive from existing conversational context.

## Research Approach

The application follows a three-stage assessment process:

1. **Ground Truth Collection** – Participants provide their actual personal attributes.
2. **User Awareness Assessment** – Participants estimate which attributes an LLM could infer about them.
3. **LLM Inference Evaluation** – The LLM's inferred attributes are collected and compared against the ground truth and participants' expectations.

## Assessment storage and API

An `Assessment` stores the random public UUID, age group, selected LLM application,
instrument version and completion timestamp. It owns exactly eight
`AttributeResponse` records, one per category. Each response stores the original
expectation, the inference status and the participant's rating. Foreign keys,
unique indexes and check constraints protect these relations and allowed values.
Unfinished assessments retain their expectations; pending evaluation fields are SQL
`NULL`. No chat history, memory, concrete inference value or independent ground
truth is stored.

`POST /form/submissions` accepts JSON with `assessment_id`, `step` and `data`:

- `baseline`: `data.basis` contains `age_group` and `model`;
  `data.expectations` contains all eight category keys with `yes` or `no`.
- `evaluation`: `data.ratings` contains all eight category keys with `correct`,
  `incorrect` or `invalid`; `data.inference_statuses` contains the same keys with
  `provided`, `not_inferred` or `refused`. The browser derives these statuses
  locally from a string, JSON `null` or `SICHERHEITSRICHTLINIE`, respectively.
  `not_inferred` and `refused` require the rating `invalid`.

The categories are `alter`, `geschlecht`, `beziehungsstatus`, `wohnort`,
`geburtsort`, `bildungsstand`, `beruf` and `einkommen`. Unexpected fields and
incomplete or inconsistent answers return 422. Evaluation requires a saved baseline
(404 otherwise). Identical retries return 200 without duplicate records or timestamp
changes; attempts to overwrite submitted answers return 409. Both submission steps
are transactional. Submitted data and identifiers are filtered from request logs.

`Assessment.completed` selects completed assessments. `Assessment#evaluation`
returns counts and separate gap, underestimation and overestimation rates for a
completed assessment; it returns `nil` for an unfinished assessment. The denominator
includes provided answers rated correct or incorrect, plus non-inferences (`null`).
A non-inference with expectation `yes` counts as overestimation, while expectation
`no` counts as agreement. Safety refusals and provided answers rated invalid are
excluded and counted separately. Rates are `nil` when the denominator is zero.
Counts remain available for later evaluation, including the number of exclusions.
The instrument version identifies the questionnaire and prompt contract; increment
it when that contract changes and keep different versions separate in future studies.
Public aggregate results are served as Inertia props on `GET /result`. Individual
evaluation data is not exposed by a read endpoint.

### Results configuration

Copy `.env.example` to `.env` for local development (`cp .env.example .env`).
Rails loads `.env` automatically in development and test; existing environment
variables take precedence. The local file is ignored by Git, while `.env.example`
is versioned.

Set `RESULTS_MIN_PARTICIPANTS=10` in `.env` (10 is the default), then restart Rails.
In production, set the variable in the server environment. The value must be a positive integer; invalid values prevent
startup. Only completed assessments of `Assessment::INSTRUMENT_VERSION` count.
Below the threshold the response contains no participant counts, rates or subgroup
data. The server enforces the threshold for both initial HTML and Inertia requests,
ignores client-supplied filters and sends `Cache-Control: no-store`.

The results page shows pooled gap, underestimation and overestimation rates,
agreement, category comparisons, a four-cell expectation/outcome table, coverage,
non-inferences, exclusions and the equally weighted mean individual gap. A rate
with denominator zero remains undefined. Every published age group must reach the
configured participant threshold. Undersized age groups are omitted server-side;
if their combined remainder is below the threshold, the smallest otherwise eligible
age group is also omitted to protect against reconstruction from overall totals.
If no age groups can be published, the age section is hidden entirely. LLM
breakdowns remain withheld as a whole when any represented LLM group is too small.
No intersections of age and LLM are published. These are minimum group-size rules,
not a guarantee against all disclosure risks, including changes between visits.

The public results page contains aggregated results only. It does not display or
retain a personal evaluation, and no individual results are fetched by assessment
identifier. The methodology remains visible while results are locked.

Model specs cover the measurement rules, pending versus imported nulls, relational
constraints and zero-denominator cases. Request specs cover publication thresholds, persistence, validation,
transaction rollback, retries and conflicts. Browser specs cover the two approved
transfers, local processing of inference values and transmission of null/refusal
statuses. Additional result specs cover subgroup suppression, weighting, undefined
rates, responsive charts and aggregate-only result navigation. These checks exercise storage and evaluation requirements FA-09–FA-13 and
reproducibility/error handling QA-04–QA-05 from the thesis; they do not replace an
empirical study of the prompt or a representative awareness survey.

## Technology

Built with Ruby on Rails, Svelte, and Inertia.js.

## Development

This repository was bootstrapped using the [Rails + Svelte starter template](https://github.com/georgekettle/rails_svelte).

## Local test pipeline

Run all checks with:

```sh
bin/test
```

Runs linting, security analysis, the production frontend build, Rails checks, and
RSpec. Chromium tests run when `spec/features` exists. Enable the pre-commit hook
once per clone with `git config --local core.hooksPath .githooks`.

---

<sub>This README was generated with the assistance of AI.</sub>
