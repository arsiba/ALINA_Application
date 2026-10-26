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
