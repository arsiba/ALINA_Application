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

After both submission steps succeed, the form completion screen calculates a
personal awareness score locally: agreement / evaluable categories, equivalent to
1 minus the personal gap rate. Nulls, exclusions and both gap directions follow the
same measurement rules as the aggregate results. With no evaluable categories the
score is undefined. This personal display is independent of the publication
threshold because no other participants' data is used. It is computed from the
already approved submission payloads, without sending extra data or storing the
score in cookies, browser storage, history state or a shared store. Reloading or
leaving the form discards the completion screen. A prominent warning explains that
the personal score is not stored for later retrieval, while the approved research
answers are still saved as described before submission.

Model specs cover the measurement rules, pending versus imported nulls, relational
constraints and zero-denominator cases. Request specs cover publication thresholds, persistence, validation,
transaction rollback, retries and conflicts. Browser specs cover the two approved
transfers, local processing of inference values and transmission of null/refusal
statuses. Additional result specs cover subgroup suppression, weighting, undefined
rates, responsive charts and aggregate-only result navigation. These checks exercise storage and evaluation requirements FA-09–FA-13 and
reproducibility/error handling QA-04–QA-05 from the thesis; they do not replace an
empirical study of the prompt or a representative awareness survey.

## Participation cookie and legal assessment

After the last successful submission, Rails sets `alina_participated=1` for 30 days.
The value is identical for every completed browser: no UUID, timestamp, model,
answers or score is stored in this cookie. It is host-only, HttpOnly, SameSite=Lax,
and Secure on HTTPS. Neither visits nor idempotent submission retries renew it.
No marker is set for unfinished or failed submissions. Personalized page props are
served with `Cache-Control: no-store`.

The marker enforces the study's one-participation rule within the same browser:
the form shows a completion notice and the submission endpoint returns 409 for new
assessments or other unfinished assessments. Exact retries for an already completed
assessment still pass normal payload verification. The cookie is not an identity
check, is not bound to an assessment UUID, and does not stop deletion, browser
changes, simultaneous requests before it is received, or deliberate manipulation.
Shared browsers may also prevent another person from taking part. No IP-based
fingerprinting or additional participant identifier was introduced.

The banner is informational, with a “Verstanden” button; it is not a consent
request. Dismissal stays only in JavaScript memory during Inertia navigation and
sets no cookie or browser-storage entry. The notice can be reopened in the footer.
`GET /cookies` describes the marker, the existing encrypted Rails security/session
cookie, retention, purpose, browser controls and the legal assessment. The session
cookie is separate from the constant participation flag and does contain technical
session data; it must not be described as having no data at all.

Legal research as of 31 October 2026, scoped to EU/Germany:

- [Section 25 TDDDG](https://www.gesetze-im-internet.de/ttdsg/__25.html) generally
  requires consent for device storage/access, with a narrow exception for what is
  strictly necessary for an explicitly requested service (paragraph 2, number 2).
  This applies even without personally identifiable cookie contents.
- The [DSK guidance, section III.3.b, especially paragraphs 756–759 and 866–874](https://datenschutzkonferenz-online.de/media/oh/20221130_OH_Telemedien_Version_1.1.pdf)
  allows consideration of user-oriented fraud prevention but rejects blanket
  “security cookie” classifications. Purpose, timing, duration, contents and access
  must each be limited and justified.
- The implementation's necessity assessment rests on the explicitly required
  one-participation survey function and an actual server-enforced browser guard,
  rather than a convenience reminder, audience measurement or research benefit
  alone. This is a project-specific legal inference, not an authority's ruling on
  ALINA. Limited effectiveness does not establish strict necessity by itself.
- Before deployment, the study operator must confirm the applicability of that
  exception, justify the 30-day duration against the actual collection period and
  consider the operating jurisdiction. If that assessment does not support the
  exception, the marker needs a valid consent flow; relabeling it is insufficient.
  Cookie access law does not determine the separate GDPR legal basis for study
  responses, operational logs or other personal-data processing. A controller's
  privacy notice and responsibilities remain necessary.

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
RSpec. Chromium tests run when browser specs exist. GitHub Actions runs these checks
for every push and pull request. The former pre-commit hook has been removed;
existing clones can clear its configuration with `git config --unset core.hooksPath`.

## CI, images and releases

The [GitHub repository](https://github.com/arsiba/ALINA_Application) is the primary
remote. CI runs linting, Brakeman, npm vulnerability checks, Rails checks, frontend
builds, RSpec and Chromium tests. Evaluation reports are also generated when
`bin/evaluate` exists. Logs and evidence are retained as workflow artifacts for 14 days.
The production Docker image must build and pass HTTP and asset smoke tests.

Successful pushes to `main` publish `ghcr.io/arsiba/alina_application:main` and
`sha-<full commit>`. To release a tested commit on `main`, push a version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The tag workflow repeats the checks, validates that the commit belongs to `main`,
publishes the versioned image and `latest`, then creates a GitHub Release with
generated notes. Use `vMAJOR.MINOR.PATCH`; `latest` tracks the last released tag.
Publishing uses the built-in `GITHUB_TOKEN`; no registry password is required.
Pull requests build and test images without publishing them. Weekly CI reruns
security checks. Dependabot opens weekly updates for Bundler, npm, Actions and
Docker; `.npmrc` preserves the existing legacy peer dependency resolution.

Run a published image behind an HTTPS reverse proxy with a persistent SQLite volume:

```sh
docker run -d -p 8080:80 -v alina-storage:/rails/storage \
  -e SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  ghcr.io/arsiba/alina_application:main
```

Keep `SECRET_KEY_BASE` stable across restarts in your deployment's secret store.
The container prepares its databases on startup. TLS termination is required by
Rails' production SSL configuration. Releases publish artifacts; deployment remains
a separate operational step.

---

<sub>This README was generated with the assistance of AI.</sub>
