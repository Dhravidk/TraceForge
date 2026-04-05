# TraceForge CLI-First Demo Readiness Plan

## Purpose

This is the active execution plan for turning TraceForge into a first-place-caliber JacHacks submission.

The product direction is now explicit:

- TraceForge is an **AI-coding-first CLI tool**
- the primary users are operators inside **Codex CLI** and **Claude Code**
- the primary value is **better trajectory analysis through better evidence structure**
- the UI is secondary and should be treated as an optional appendix and fallback demo surface

This plan is intentionally more detailed than the earlier completion plans because we need two things at once:

1. a terminal-first product story strong enough to win the hackathon
2. a coordination model that lets multiple agents work in parallel without overwriting each other

## Mission

Ship a version of TraceForge that a developer or coding agent can install from the GitHub URL alone, run from the terminal, and use immediately to transform raw coding-agent trajectories into structured evidence packs that Codex or Claude Code can reason over more effectively.

The winning story is not:

> we built a nicer trace browser

The winning story is:

> developers already work in Codex CLI and Claude Code, and TraceForge upgrades that workflow by compiling raw trajectories into graph-backed evidence packs that are easier for agents to analyze correctly

## Product Positioning

TraceForge should be presented as:

> a graph-backed CLI for compiling coding-agent trajectories into structured evidence packs, critical-step localizations, recurring-failure clusters, and reusable memory rules

It should not be presented primarily as:

> a UI for browsing logs

That means the default user journey is:

1. clone repo
2. run install/bootstrap
3. run `traceforge doctor`
4. analyze a sample or uploaded batch
5. inspect a run or cluster in the terminal
6. generate `raw` and `structured` evidence packs
7. feed those packs into Claude Code or Codex
8. optionally run built-in comparison or export artifacts

## Winning Demo Thesis

The strongest sentence in the demo should be:

> same failed run, same outer model, better evidence pack

That is a cleaner and more defensible story than "our model beats their model."

The built-in provider-backed comparison is still useful, but it should support the story rather than define it.

## First-Place Success Criteria

To feel like a first-place submission, TraceForge needs to hit all of these:

1. The repo can be understood without reading source.
2. A coding agent can install and run the tool from the docs alone.
3. The CLI is clearly the primary product surface.
4. The Jac graph is visibly essential to the core value.
5. The raw-versus-structured evidence difference is obvious in one terminal session.
6. Provider-backed comparison works when available and fails clearly when unavailable.
7. The demo has a safe fallback path that still lands the thesis.
8. The repo and docs look deliberate, not hacky.

## Current Baseline

The repo already has:

- Jac-native parsing, graph compilation, clustering, and critical-step localization
- graph-backed walkers for batch, run, cluster, comparison, and report flows
- sample and local upload ingestion
- provider config support for OpenAI, Anthropic, and Codex CLI
- exports for blinded evaluation, rigorous summaries, gold annotations, and reports
- a working UI path and a stronger visual layer than before

The underlying engine is strong enough.
The product surface is what now needs to be shaped.

## Main Gaps

### Gap 1: The public interface is still Jac-internal

`jac enter main.jac ...` is acceptable for development and weak for product use.
It exposes walkers, positional argument quirks, and Jac-specific mechanics that users should never need to know.

### Gap 2: Pack generation is not yet the primary product surface

The most valuable workflow is:

- show me the raw evidence pack
- show me the structured evidence pack
- let my coding agent reason over the difference

That workflow exists internally but is not yet the center of the tool.

### Gap 3: Provider execution is not demo-safe enough

Provider-backed evaluation can degrade into deterministic fallback.
That is acceptable for local development and dangerous in a live demo if not surfaced clearly.

### Gap 4: The repo docs are not yet operator-grade

A user should be able to paste the GitHub URL into Codex or Claude Code and have the agent install and run TraceForge from the README and CLI docs alone.
The current docs still read like a Jac project README, not a polished tool manual.

### Gap 5: The demo story is still split between UI and CLI

That makes the product feel undecided.
We need one primary demo path and one fallback path.

### Gap 6: Parallel implementation is still underspecified

If multiple agents work at the same time, they can still collide on shared files, docs, and public command surfaces unless we define ownership and merge rules tightly.

## Review-Driven Corrections

The latest external review is directionally correct on one central point:

> TraceForge has a credible shell around a still-underpowered core.

That means the next phase cannot be more CLI polish, more UI polish, or more submission copy.
The next phase has to strengthen the irreducible product insight:

- honest batch motif discovery
- stronger evidence-grounded memory synthesis
- consistent provider behavior
- inspectable real-data proof

The active product plan is therefore updated with these rules:

1. No major new UI work until the core analysis is stronger.
2. No new docs-only work unless it removes ambiguity or reflects new shipped capability.
3. Any new marketing claim must be backed by a checked-in artifact, a runtime test, or an inspectable evaluation bundle.
4. Core algorithm work now outranks shell polish.

## Immediate Priority Reset

The next shipping milestone is not "nicer CLI."

It is:

> TraceForge can ingest a real batch, discover repeated motifs honestly, produce cluster-derived memory guidance, and show inspectable proof that the structured pack improves downstream analysis.

That milestone breaks down into six hard requirements:

1. Clustering must become global-first, not family-first.
2. The similarity function must be cleaned up and made defensible.
3. Memory patches must become cluster-derived before templated rendering.
4. LLM-backed diagnosis and patch flows must support the same provider matrix as compare.
5. The repo must ship one small but inspectable real evaluation bundle.
6. The stale graph / graph reuse edge cases must be resolved so real-batch runs are trustworthy.

## Non-Negotiable Product Truths

These points should govern every implementation decision:

- TraceForge is strongest when it acts as a postmortem compiler for coding-agent trajectories.
- The key differentiator is still "same failed run, same outer model, better evidence pack."
- If the structured pack is not materially better than raw transcript analysis, the product story collapses.
- If clustering is not honest, the batch-analysis story collapses.
- If memory patches are obviously templated, the long-term learning story collapses.

## Execution Order

The work should now happen in this order:

1. Fix correctness and trust issues in the core analysis path.
2. Ship inspectable evidence that the core path works on real data.
3. Unify provider behavior across compare, diagnosis, and patch flows.
4. Then polish CLI UX and docs where needed.
5. Only after that, touch the UI again.

## Workstream 0: Graph Correctness And Rebuild Trust

### Objective

Eliminate ambiguity about whether TraceForge is reading current parsed data or stale graph state.

### Why this exists

We already saw evidence that real external batches can report misleading reused graph state.
If batch invalidation and rebuild are not trustworthy, every higher-level claim becomes suspect.

### Deliverables

- explicit graph versioning tied to parser/fingerprint schema
- forced rebuild when parser version or batch file set changes
- clear CLI reporting of `graph_reused` versus `graph_rebuilt`
- batch summary checks that surface stale graph mismatch

### Required implementation changes

- add a graph schema/version stamp to batch metadata
- hash the batch file manifest and parser version into graph identity
- make `ensure_batch_graph` rebuild when stored graph identity no longer matches current input identity
- make `doctor` or `overview` expose graph freshness state for the current batch

### Done when

- a real uploaded batch cannot silently keep an outdated analysis graph
- operators can tell whether the graph was rebuilt from current parser logic

## Workstream 1: Honest Global Clustering

### Objective

Replace family-first clustering with global motif discovery followed by labeling.

### Why this exists

Today the clustering claim is weaker than the pitch because runs are grouped by `primary_failure` before clustering.
That yields subclusters within a pre-labeled family instead of honest motif discovery across the batch.

### Deliverables

- global similarity graph across all failed runs
- connected components or alternative cluster assignment over the full batch
- post-cluster labeling based on the cluster aggregate, not pre-bucketed family
- revised starter/demo data that actually shows repeated motifs

### Required implementation changes

- remove the initial `by_family` bucketing step from [clustering.jac](/home/gb10/Projects/JacHacks/traceforge/clustering.jac)
- build similarity neighbors across the entire run set
- compute cluster-level failure labels from aggregate signals after clusters exist
- update cluster summaries to say when a cluster is mixed or weakly labeled
- replace the "4 runs -> 4 clusters" expectation in the smoke/demo story with a motif-producing sample

### Acceptance criteria

- the system can discover repeated motifs even when the runs do not share the same initial dominant family
- cluster labels can differ from individual-run dominant family labels when the cluster evidence supports it

## Workstream 2: Similarity Function Repair

### Objective

Make the run similarity score technically defensible.

### Why this exists

The current similarity function double-counts lexical overlap, which makes the core analysis look undercooked.

### Deliverables

- repaired weight distribution in `similarity_score`
- one additional distinct feature to replace the duplicated lexical term
- documented rationale for every weighted feature

### Candidate replacement features

- critical-step alignment overlap
- exit-status compatibility
- patch/test temporal ordering similarity
- hypothesis-score overlap

### Required implementation changes

- remove duplicated lexical weighting
- add one new feature with a clear interpretation
- document the feature mix in code comments and operator docs
- add targeted tests that compare at least a few synthetic fingerprints with expected relative ordering

### Done when

- the similarity score reads like an intentional design instead of an accidental blend

## Workstream 3: Cluster-Derived Memory Synthesis

### Objective

Make memory patches emerge from cluster evidence instead of starting from canned failure-family templates.

### Why this exists

This is currently the weakest part of the product moat.
If the patch is visibly "template plus seasoning," then the trajectory-to-memory compiler story does not hold.

### Deliverables

- cluster-level evidence extraction for repeated conditions, repeated bad actions, and repeated failed validations
- rule synthesis from those evidence records
- templated phrasing only as a final rendering layer, not as the logical source of the rule

### Required synthesis pipeline

1. derive repeated cluster conditions
2. derive repeated failure-triggering actions
3. derive repeated missing validation steps
4. derive concrete guardrails
5. render those guardrails into AGENTS.md-compatible text

### Required implementation changes

- move from failure-class-first rule generation to evidence-record-first rule generation in [llm_ops.jac](/home/gb10/Projects/JacHacks/traceforge/llm_ops.jac)
- preserve supporting steps and supporting runs for every generated rule
- mark each memory rule with provenance:
  - derived from cluster evidence
  - derived from weak evidence
  - fallback template

### Acceptance criteria

- a reviewer can look at a generated rule and trace it back to repeated evidence across multiple runs
- fallback templated rules remain available, but are clearly marked as fallback

## Workstream 4: Provider Unification

### Objective

Make compare, diagnosis, cluster analysis, and memory synthesis use one consistent provider model.

### Why this exists

The current product behavior is split-brain:

- compare is provider-aware
- diagnosis and patch logic are effectively gated by OpenAI availability

That is a confusing user experience and weakens the Codex/Claude workflow story.

### Deliverables

- one provider resolution path shared by compare, run diagnosis, cluster diagnosis, and patch synthesis
- one CLI-visible provider mode for the entire session
- one clear fallback story when no live provider is available

### Required implementation changes

- remove OpenAI-only gating from [llm_ops.jac](/home/gb10/Projects/JacHacks/traceforge/llm_ops.jac)
- route all LLM-backed synthesis through the shared provider config layer
- expose the resolved provider in all LLM-backed command outputs
- add strict-mode behavior where relevant beyond compare

### Done when

- a user can choose Codex, OpenAI, or Anthropic once and get consistent behavior across all LLM-backed flows

## Workstream 5: Inspectable Real-Data Proof

### Objective

Ship a small but checkable evidence bundle in the repo.

### Why this exists

The repo currently describes real-data validation but does not ship inspectable proof artifacts.
That keeps the product in "narrative evidence" territory.

### Deliverables

- one small checked-in real or redacted batch slice
- one matching gold annotation file
- one saved raw pack
- one saved structured pack
- one saved compare artifact
- one saved report artifact
- one short note explaining what the artifact proves and what it does not prove

### Scope target

- 10 to 20 runs is enough
- repeated motifs must actually exist
- at least one case should show provider-backed comparison if credentials and safety allow

### Constraints

- no secrets
- no giant binary dumps
- no unreviewed benchmark claims

### Done when

- a reviewer can inspect the repo alone and see a concrete real-data example of the product thesis

## Workstream 6: Starter Data Replacement

### Objective

Replace the current smoke fixture as the main demo proof with a slightly richer, motif-bearing starter slice.

### Why this exists

The current starter sample is useful for smoke testing and weak for persuasion.

### Deliverables

- keep the current tiny fixture for fast tests
- add a second checked-in demo batch whose main purpose is motif discovery
- update demo docs to use the richer sample while preserving the tiny sample for smoke tests

### Done when

- the canonical demo naturally shows repeated failure patterns rather than one cluster per run

## Workstream 7: Repo Trust Signals

### Objective

Bring the repo up to the minimum standard expected of a credible open-source tool.

### Deliverables

- `LICENSE`
- basic CI workflow for smoke checks
- reduced README overclaiming
- a cleaner separation between operator docs and submission docs

### Required rules

- README claims must map to code or checked-in artifacts
- submission docs should not substitute for proof artifacts
- internal planning docs should not be mistaken for operator documentation

### Done when

- the repo feels like a real tool repository, not a judging packet

## Product Contract

By demo time, the product should behave like this:

### Primary operator workflow

```bash
traceforge doctor
traceforge analyze-batch --batch sample-starter --input demo_runs/starter_batch
traceforge overview --batch sample-starter
traceforge run --batch sample-starter --run invalid_patch
traceforge pack --batch sample-starter --run invalid_patch --mode raw --format md
traceforge pack --batch sample-starter --run invalid_patch --mode structured --format md
```

### Optional provider-backed workflow

```bash
traceforge compare --batch sample-starter --run invalid_patch --provider codex --strict-provider
traceforge export-eval --batch sample-starter --provider openai --strict-provider
```

### Artifact workflow

```bash
traceforge export-report --batch sample-starter
traceforge export-eval --batch sample-starter
```

## What The CLI Must Expose

The public CLI surface should be intentionally small.

### Core commands

- `traceforge doctor`
- `traceforge analyze-batch`
- `traceforge overview`
- `traceforge run`
- `traceforge cluster`
- `traceforge pack`
- `traceforge compare`
- `traceforge export-report`
- `traceforge export-eval`
- `traceforge auth status`
- `traceforge auth use`
- `traceforge auth clear`

### Output modes

Every command that matters should support:

- human-readable terminal output by default
- `--json` for automation

### Guarantees

The CLI should provide:

- stable exit codes
- stable field names in JSON mode
- no Python-dict-style stdout as the public interface
- clear mode reporting:
  - provider-backed
  - deterministic fallback
  - export-only

## Workstreams

## Workstream 1: Public CLI Wrapper

### Objective

Ship a first-party `traceforge` entrypoint so users no longer operate the product through raw Jac walker calls.

### Deliverables

- wrapper entrypoint
- named flags
- normalized output rendering
- `--json`
- consistent exit codes
- mapping from CLI subcommands to Jac walkers

### Required behavior

- the CLI should hide walker names
- the CLI should hide positional Jac argument quirks
- error messages should be operator-friendly

### Candidate files

- `main.jac`
- [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)
- [provider_config.jac](/home/gb10/Projects/JacHacks/traceforge/provider_config.jac)
- new wrapper files such as:
  - `traceforge/cli.jac`
  - `traceforge/cli.py` packaging shim
  - `scripts/traceforge`
  - package entrypoint metadata

### Done when

- the primary README never needs `jac enter` in the first-run flow
- users can discover the product from `traceforge --help`

## Workstream 2: Pack-First Product Surface

### Objective

Make evidence-pack generation the center of the product.

### Deliverables

- `pack --mode raw`
- `pack --mode structured`
- markdown output optimized for pasting into Codex or Claude Code
- JSON output optimized for automation

### Required structured-pack contents

- task summary
- failure-family guess
- localized critical-step candidates
- exact evidence windows
- top files, errors, and tests
- cluster context
- memory rule or patch hint if available

### Required raw-pack contents

- compressed trajectory
- canonical step mapping
- enough context for a baseline analysis

### Done when

- the pack commands can carry the demo even if live provider-backed compare is unavailable

## Workstream 3: Provider And Auth Hardening

### Objective

Make provider execution explicit, reliable, and demo-safe.

### Deliverables

- `traceforge doctor`
- `traceforge auth status`
- `traceforge auth use codex|openai|anthropic`
- `traceforge auth clear`
- `--strict-provider`
- clear exit codes and error messages

### Required checks in `doctor`

- Codex CLI installed or missing
- Codex CLI logged in or not
- OpenAI key present or absent
- Anthropic key present or absent
- active provider selection
- resolved provider
- strict-mode viability
- path to config file

### Required behavior

- strict mode must exit non-zero on provider failure
- no silent fallback in strict mode
- explicit warning when non-strict mode falls back
- output must clearly distinguish:
  - live provider verdict
  - deterministic fallback verdict
  - no-provider mode

### Done when

- an operator cannot accidentally misstate what produced a result

## Workstream 4: Installation And Bootstrap

### Objective

Make installation simple enough that a coding agent can infer the setup from the repo docs alone.

### Deliverables

- one clear setup path for macOS and Linux
- one bootstrap script or Make target
- one "quick install" sequence near the top of the README
- a working `doctor` command immediately after install

### Required operator experience

A user should be able to instruct Codex or Claude Code:

> clone the repo, install TraceForge, run the sample batch, and show me the structured pack for one failed run

and the agent should succeed without reading implementation files.

### Done when

- install fits in a short Quickstart section
- setup errors are caught by `doctor`

## Workstream 5: Output Normalization

### Objective

Make outputs stable enough for both humans and agents.

### Deliverables

- normalized JSON schemas
- readable terminal rendering
- consistent field names
- artifact metadata on all export-producing commands

### JSON fields that should exist consistently

- `status`
- `mode`
- `provider`
- `provider_available`
- `strict_provider`
- `batch_id`
- `run_id`
- `cluster_id`
- `artifact_paths`
- `comparison_mode`
- `warning`
- `error`

### Done when

- Claude Code or Codex can parse outputs reliably
- the public interface no longer leaks internal development formatting

## Workstream 6: Docs Rewrite

### Objective

Rewrite the docs so the repo reads like a polished CLI tool for AI coding workflows.

### README must answer these questions immediately

1. What is TraceForge?
2. Who is it for?
3. Why would I use it inside Codex CLI or Claude Code?
4. How do I install it?
5. How do I run one sample workflow?
6. How do I generate raw and structured packs?
7. How do I use provider-backed compare if I want it?
8. Where do artifacts land?

### New docs to add

- `docs/cli/quickstart.md`
- `docs/cli/provider_setup.md`
- `docs/cli/agent_workflows.md`
- `docs/cli/demo_playbook.md`
- `docs/cli/output_schema.md`

### Existing docs to rewrite

- [README.md](/home/gb10/Projects/JacHacks/README.md)
- [demo_script.md](/home/gb10/Projects/JacHacks/docs/submission/demo_script.md)
- [devpost_outline.md](/home/gb10/Projects/JacHacks/docs/submission/devpost_outline.md)
- [judging_notes.md](/home/gb10/Projects/JacHacks/docs/submission/judging_notes.md)

### Required documentation standard

Every public command should have:

- one-line purpose
- one copy-paste example
- expected output form
- failure mode notes

### Done when

- the repo can onboard a new user without source diving
- the docs feel like product docs, not internal notes

## Workstream 7: Demo Hardening

### Objective

Make the terminal demo survive provider issues, quota issues, and operator mistakes.

### Deliverables

- one canonical live demo path
- one canonical fallback path
- one canonical sample run
- precomputed backup artifacts
- a short operator cheat sheet

### Primary demo flow

1. `traceforge doctor`
2. `traceforge analyze-batch --batch sample-starter ...`
3. `traceforge run --batch sample-starter --run invalid_patch`
4. `traceforge pack --batch sample-starter --run invalid_patch --mode raw`
5. `traceforge pack --batch sample-starter --run invalid_patch --mode structured`
6. `traceforge compare ... --strict-provider` if live provider is available

### Fallback demo flow

1. `traceforge doctor`
2. `traceforge run ...`
3. `traceforge pack ... --mode raw`
4. `traceforge pack ... --mode structured`
5. open exported comparison JSON or rigorous markdown summary

### Done when

- the demo still lands even if provider-backed compare cannot run live

## Workstream 8: Submission Story Rewrite

### Objective

Make the pitch, README, and Devpost all tell the same terminal-first story.

### Story to emphasize

- developers already work in Codex and Claude Code
- TraceForge plugs into those workflows
- Jac is essential because it provides the graph model and walkers
- the value is better evidence structure, not just another UI

### Demo soundbite

> same failed run, same outer model, better evidence pack

### Done when

- the product story feels focused and memorable

## Workstream 9: Minimal UI Strategy

### Objective

Keep the UI healthy enough for backup use without spending product energy there.

### Rules

- no large new feature work in the UI unless it supports the CLI story directly
- the UI remains a fallback artifact viewer and optional judge appendix
- README should not lead with the UI

### Done when

- the UI does not distract from the main CLI product

## Workstream 10: Verification And Acceptance

### Objective

Define what "done" means in a way that multiple agents can work against cleanly.

### Acceptance checks

- sample install flow works from docs
- `traceforge doctor` reports correct mode
- sample batch can be analyzed from CLI
- raw pack renders cleanly
- structured pack renders cleanly
- compare either:
  - runs live in strict mode, or
  - fails clearly and predictably
- report and eval exports land in documented paths
- README quickstart matches actual commands

## Parallel Execution Model

This repo should now be treated as a multi-agent workspace with strict ownership.

The rule is:

> one workstream owns a file set at a time; shared integration files are edited only by the integrator unless explicitly handed off

## Roles

### Integrator

Owns:

- `README.md`
- `main.jac`
- public command naming
- cross-workstream architecture decisions
- final merge decisions
- final demo path

Responsibilities:

- keep product shape coherent
- resolve interface conflicts
- merge worker output
- guard the public CLI contract

### Worker A: Parser And Graph Correctness

Owns:

- [parser.jac](/home/gb10/Projects/JacHacks/traceforge/parser.jac)
- [graph_build.jac](/home/gb10/Projects/JacHacks/traceforge/graph_build.jac)
- parser fixtures
- graph freshness tests

Responsibilities:

- improve parser fidelity
- fix stale graph and rebuild trust
- keep parsed metadata and graph state aligned

### Worker B: Clustering And Similarity

Owns:

- [clustering.jac](/home/gb10/Projects/JacHacks/traceforge/clustering.jac)
- clustering-related slices of [features.jac](/home/gb10/Projects/JacHacks/traceforge/features.jac)
- motif-bearing demo/eval sample design

Responsibilities:

- replace family-first clustering
- repair similarity scoring
- move cluster labeling to post-cluster analysis

### Worker C: Memory Synthesis And Pack Quality

Owns:

- [llm_ops.jac](/home/gb10/Projects/JacHacks/traceforge/llm_ops.jac)
- pack-related slices of [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)
- pack-facing slices of [analysis.jac](/home/gb10/Projects/JacHacks/traceforge/analysis.jac)

Responsibilities:

- make memory patches cluster-derived
- preserve rule provenance and supporting evidence
- improve what the downstream model actually sees

### Worker D: Provider And Auth

Owns:

- [provider_config.jac](/home/gb10/Projects/JacHacks/traceforge/provider_config.jac)
- provider-related slices of [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- provider-related slices of [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)

Responsibilities:

- unify provider behavior across compare, diagnosis, and patch flows
- keep strict-provider behavior honest
- keep fallback semantics explicit

### Worker E: Real-Data Evidence And Repo Trust

Owns:

- checked-in artifact bundles
- gold annotations
- validation notes
- `LICENSE`
- CI scaffolding

Responsibilities:

- convert narrative proof into inspectable proof
- keep repo claims tied to shipped artifacts

### Worker F: CLI And Docs Integrator

Owns:

- [cli.jac](/home/gb10/Projects/JacHacks/traceforge/cli.jac)
- [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- `docs/cli/*.md`
- submission docs
- [reporting.jac](/home/gb10/Projects/JacHacks/traceforge/reporting.jac)

Responsibilities:

- keep the public product surface coherent
- reflect only shipped behavior in docs
- keep demo scripts aligned with the strongest proven workflow

## File Ownership Matrix

The following ownership should be observed during implementation.

### Integrator-owned files

- `README.md`
- `main.jac`
- packaging entrypoint config
- repo-root bootstrap files
- final approval on any shared public interface changes

### Worker A-owned files

- [parser.jac](/home/gb10/Projects/JacHacks/traceforge/parser.jac)
- [graph_build.jac](/home/gb10/Projects/JacHacks/traceforge/graph_build.jac)
- parser-oriented test fixtures

### Worker B-owned files

- [clustering.jac](/home/gb10/Projects/JacHacks/traceforge/clustering.jac)
- clustering-related slices of [features.jac](/home/gb10/Projects/JacHacks/traceforge/features.jac)
- motif-bearing sample definitions and manifests

### Worker C-owned files

- [llm_ops.jac](/home/gb10/Projects/JacHacks/traceforge/llm_ops.jac)
- pack-related slices of [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)
- pack-facing slices of [analysis.jac](/home/gb10/Projects/JacHacks/traceforge/analysis.jac)

### Worker D-owned files

- [provider_config.jac](/home/gb10/Projects/JacHacks/traceforge/provider_config.jac)
- provider-related slices of [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- provider-related slices of [eval.jac](/home/gb10/Projects/JacHacks/traceforge/eval.jac)

### Worker E-owned files

- checked-in artifact bundles under a dedicated artifact subtree
- [validation_notes.md](/home/gb10/Projects/JacHacks/docs/cli/validation_notes.md)
- `LICENSE`
- `.github/workflows/*`

### Worker F-owned files

- [cli.jac](/home/gb10/Projects/JacHacks/traceforge/cli.jac)
- [api.jac](/home/gb10/Projects/JacHacks/traceforge/api.jac)
- `docs/cli/*.md`
- [demo_script.md](/home/gb10/Projects/JacHacks/docs/submission/demo_script.md)
- [devpost_outline.md](/home/gb10/Projects/JacHacks/docs/submission/devpost_outline.md)
- [judging_notes.md](/home/gb10/Projects/JacHacks/docs/submission/judging_notes.md)
- [reporting.jac](/home/gb10/Projects/JacHacks/traceforge/reporting.jac)

## Shared-File Rules

These files are shared-risk files and should not be edited casually by multiple agents:

- `main.jac`
- `README.md`
- `traceforge/api.jac`
- `traceforge/eval.jac`
- `traceforge/analysis.jac`
- `traceforge/graph_build.jac`

Rules:

1. Only the integrator edits `main.jac` and `README.md`.
2. `api.jac`, `eval.jac`, `analysis.jac`, and `graph_build.jac` changes must be time-boxed to one worker when touched directly.
3. If two workstreams need `eval.jac` or `analysis.jac`, one of them must first extract helper functions into a new owned module before parallel work continues.
4. No docs worker updates command semantics before the integrator confirms the CLI shape is stable for that cycle.

## Branch And Worktree Strategy

Each parallel agent should work in its own branch or worktree.

Recommended branch names:

- `thread/integrator-architecture`
- `thread/parser-graph`
- `thread/global-clustering`
- `thread/memory-synthesis`
- `thread/provider-unification`
- `thread/evidence-bundle`
- `thread/cli-docs`

Recommended rule:

- never have two agents committing to the same branch

Recommended worktree rule:

- one worktree per active agent if possible
- otherwise one branch per agent with disciplined rebases and merges

## Merge Protocol

Every merge cycle should follow this exact order:

1. worker finishes a small vertical slice in owned files
2. worker writes a short handoff summary:
   - commands added
   - files touched
   - interfaces changed
   - assumptions
3. integrator reviews for public-surface conflicts
4. integrator merges into the main working branch
5. integrator updates shared docs only after merge
6. next worker picks up only after shared-surface conflicts are resolved

Do not allow giant parallel branches to diverge for long.
Merge frequently and keep slices small.

## Handoff Template For Parallel Agents

Every worker handoff should include:

- objective completed
- files changed
- public commands added or changed
- JSON fields added or changed
- known limitations
- docs impact

This should be written in plain text in the handoff message or commit body.

## No-Overwrite Guardrails

To prevent overwrite damage:

1. never have two agents editing `README.md` simultaneously
2. never have two agents editing `main.jac` simultaneously
3. do not let docs workers rewrite command names while CLI workers are still renaming commands
4. do not let provider workers change default command semantics without the integrator updating docs in the same merge cycle
5. if a worker needs a shared file unexpectedly, stop and reassign ownership first

## Phase Plan

## Phase 1: Core Correctness Lock

### Goal

Eliminate the trust-destroying correctness issues first.

### Tasks

- graph freshness and rebuild correctness
- parser fidelity gaps
- similarity-function repair
- global clustering design lock

### Must happen before

- provider unification
- docs rewrites that make stronger claims
- any new demo polish

## Phase 2: Real Core Differentiation

### Goal

Make the core insight materially stronger than a trace browser.

### Tasks

- cluster-derived memory synthesis
- stronger pack content
- post-cluster labeling
- evidence provenance across rules and summaries

### Outcome

The product becomes more than shell polish around heuristics.

## Phase 3: Provider Unification

### Goal

Make all LLM-backed features follow one provider model.

### Tasks

- unify compare, diagnosis, and patch synthesis provider resolution
- strict mode beyond compare where relevant
- clear live-versus-fallback semantics

### Outcome

The Codex/Claude/OpenAI story becomes coherent.

## Phase 4: Inspectable Proof

### Goal

Ship a small but checkable real-data bundle.

### Tasks

- check in real or redacted batch slice
- add gold labels
- add saved pack, compare, and report artifacts
- tie claims in docs to these artifacts

### Outcome

Reviewers can inspect proof without trusting narrative claims.

## Phase 5: Product Surface And Demo Lock

### Goal

Polish the CLI and docs around the now-stronger core.

### Tasks

- finalize command surface
- tighten human-readable output
- finalize demo script and fallback path
- simplify docs around the proven workflow
- prepare fallback artifacts
- finish terminal demo playbook

### Outcome

The demo still works even if live providers fail.

## Risks And Mitigations

### Risk: CLI wrapper becomes too thin and leaks Jac internals

Mitigation:

- forbid raw walker names from the README quickstart
- require stable command aliases and help text

### Risk: provider fallback causes ambiguous demo output

Mitigation:

- require `--strict-provider` in all judge-facing live compare examples
- surface mode clearly in command output

### Risk: multiple agents overwrite each other on shared files

Mitigation:

- enforce ownership zones
- use separate branches/worktrees
- route shared-file changes through the integrator

### Risk: docs drift from real commands

Mitigation:

- docs update happens only after command names are frozen
- one docs owner per cycle

### Risk: UI work distracts from CLI work

Mitigation:

- freeze major UI work
- treat UI only as fallback or appendix

## Definition Of Demo Ready

TraceForge is demo ready when:

1. a fresh clone can be installed from the docs
2. `traceforge doctor` works
3. a sample batch can be analyzed from CLI
4. raw and structured packs can be produced from CLI
5. the difference between those packs is obvious
6. provider-backed compare either works clearly or fails clearly
7. export artifacts are prepared and documented
8. the README matches the live demo path exactly

## Definition Of First-Place Ready

TraceForge is first-place ready when:

- the product surface matches real AI-coding workflow
- the technical depth is visible through the CLI itself
- Jac feels essential rather than decorative
- the docs make onboarding feel intentional and professional
- the demo is simple, robust, and memorable

## Immediate Next Slice

The first implementation slice should be:

1. lock the public CLI command surface
2. implement the wrapper with `doctor`, `run`, `pack`, and `compare`
3. make pack generation the primary demo path
4. then rewrite the top of the README and add CLI quickstart docs

This slice has the highest leverage because it changes the product shape, the docs shape, and the demo shape at the same time.
