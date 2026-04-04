# JacHacks 2026 — Codex Implementation Brief V2

## Status of this document

This is the **merged V2 implementation brief** for the JacHacks project.
It is written to be handed directly to Codex or another coding agent.
It is intentionally opinionated.
It locks scope, defines architecture, gives concrete implementation order, and includes fallback rules.

If there is any conflict between feature ambition and shipping a stable demo, **shipping the stable demo wins**.

---

# 1) Project definition

## Working title

**TraceForge**

Alternative names:
- TraceWalker
- TrajGraph
- Agent Postmortem Compiler
- WalkerScope

## One-line definition

Build a **Jac-native batch failure compiler** for coding agents:

> Upload a batch of mini-SWE-agent trajectories, compile them into a structured Jac graph, cluster recurring failure motifs, localize the first irreversible mistake in each failed run, and emit a concrete memory/update artifact such as an `AGENTS.md` patch.

## Product thesis

Most existing tools stop at one of these layers:
- trace browsing,
- experiment comparison,
- generic observability,
- single-run root-cause analysis,
- or free-form LLM summaries.

This project should instead do the full loop:
1. ingest many trajectories,
2. normalize them into a graph IR,
3. cluster repeated failure motifs,
4. localize likely critical steps,
5. compile repeated lessons into reusable agent-memory patches.

This makes the product **forensics + repair synthesis**, not just observability.

## Core user questions the product must answer

1. What are the **main recurring failure clusters** in this batch?
2. For each failed run, what was the **first irreversible mistake**?
3. For each cluster, what is the **common anti-pattern**?
4. What **persistent rule** should be added to agent memory or `AGENTS.md` to reduce recurrence?

---

# 2) JacHacks fit and constraints

## Intended tracks

- Primary: **Agentic AI**
- Secondary target: **Best Claude Code + JAC Dev Tool**

## Why this fits the event

The project is strongest if Jac is visibly central in all four of these:
- **graph-native storage**,
- **walkers for traversal/analysis**,
- **`by llm()` for typed diagnosis and patch synthesis**,
- **full-stack Jac app with local demoability**.

## Hard event constraints to honor

1. The project must be a **working application using Jac and the Jaseci stack**.
2. Jac should be the **primary language for the core AI/agentic functionality**.
3. A **working demo/prototype** is sufficient.
4. A **local runnable demo** is allowed.
5. Submission must include:
   - public GitHub repo,
   - Devpost writeup,
   - 3-minute max video,
   - working demo/prototype.
6. Time is effectively **24 hours**.
7. Projects must **start at the event**.
8. The judging rewards deep use of:
   - `by llm()`,
   - walkers,
   - graph-native data modeling,
   - Jac-first implementation.

## Implication for scope

This should **not** become:
- a multi-framework observability platform,
- a full telemetry system,
- a research benchmark paper,
- a huge infra project,
- or a generic dashboard.

It should become:
- a **sharp demo**,
- on **one input format**,
- with **one clean interface**,
- and **one compelling system insight**:

> raw coding-agent trajectories are too long and repetitive to reason over directly, so we compile them into a graph and only give the model a tiny evidence pack.

---

# 3) Locked MVP scope

## Build this exact product

The app should support this flow:

1. User uploads or loads a batch of **mini-SWE-agent** `*.traj.json` files.
2. App parses them into typed run/step/artifact objects.
3. App compiles them into a Jac graph.
4. App computes deterministic run features and failure signals.
5. App assigns each run to a top-level failure family.
6. App builds within-family run similarities.
7. App forms clusters using a simple graph-based clustering approach.
8. App localizes a likely critical step for each failed run.
9. App uses `by llm()` only on a small evidence pack.
10. App displays:
    - failure clusters,
    - representative run,
    - critical-step evidence,
    - cluster-level `AGENTS.md` patch.

## MVP deliverables

The MVP is complete when all of the following work:

- upload or load a sample batch,
- show batch summary,
- show 3–8 meaningful clusters,
- open cluster detail,
- open representative run,
- highlight critical step,
- show typed diagnosis,
- show generated `AGENTS.md` patch,
- show one baseline-vs-structured comparison.

## Stretch goals

Only after the MVP is stable:
- nearest successful contrast run,
- small query box like “why do these runs fail?”,
- multiple batch comparison,
- exporting markdown report,
- Jac-specific patch mode using docs/context snippets.

## Non-goals

Do **not** build these during the hackathon:
- general-purpose vector DB retrieval,
- live tracing instrumentation,
- full OpenInference ingestion,
- support for many harness formats,
- exact causal proof of root cause,
- enterprise-scale dashboards,
- polished auth/multi-user flows.

---

# 4) Demo substrate and data plan

## Input format

Support **mini-SWE-agent** only for the MVP.

### Why mini-SWE-agent

It gives you:
- documented `.traj.json` outputs,
- full run history,
- model stats,
- exit status,
- submission,
- inspector tooling,
- and a simple controlled benchmark workflow.

## Recommended demo data strategy

Use **pre-generated sample trajectories** for the live demo.

Do not rely on generating runs live during judging.

### Recommended data mix

Prepare:
- one batch with **20–50 runs** for fast local demo,
- one preloaded larger batch with **60–120 runs** for screenshots and stress testing,
- one small curated evaluation set of **10 failed runs** for baseline comparison.

### Recommended generation strategy

Run the same small issue slice under multiple configs to induce failure diversity.

Examples:
- weak model vs stronger model,
- lower step limit vs higher step limit,
- agent prompt variant A vs B,
- tool-use enabled vs less capable setting.

This should create recurring motifs such as:
- oscillation,
- premature completion,
- bad patching,
- wrong-file focus,
- stale planning,
- tool misuse.

### Important rule

For the pitch, say:
- **“architected for larger batches”**
- **“demoed on 20–100 trajectories”**

Do **not** claim benchmark-level performance improvement from a tiny sample.

---

# 5) Core design principles

## Principle 1 — batch failure compiler, not dashboard

This project is **not** a nicer trace viewer.
It is a system that turns many raw runs into:
- recurring failure clusters,
- auditable diagnoses,
- reusable memory rules.

## Principle 2 — parse first, retrieve second, LLM last

Never make the LLM do the initial heavy lifting.

Correct order:
1. parse raw trajectories,
2. segment them into steps,
3. extract deterministic signals,
4. build graph IR,
5. cluster runs,
6. localize critical-step candidates,
7. retrieve a tiny evidence pack,
8. ask the LLM to validate/label/synthesize.

## Principle 3 — no raw-log RAG

Do **not** chunk whole trajectories and retrieve them with generic embeddings.

Instead use:
- graph retrieval,
- lexical retrieval over compact summaries,
- feature-based similarity,
- explicit critical-step windows.

## Principle 4 — the LLM never sees the full corpus

The model should only ever see:
- one run evidence pack,
- or one cluster prototype pack.

## Principle 5 — cluster-level patches matter more than run-level patches

One run may be noisy.
Repeated failures across a cluster are real lessons.

The patch compiler should therefore be primarily **cluster-level**.

---

# 6) System architecture

The system has seven layers.

## Layer 1 — ingestion
Input:
- folder or zip of `*.traj.json`
- optionally metadata files

Output:
- raw artifacts stored locally
- `Batch` and `Run` nodes

## Layer 2 — normalization
Convert raw trajectory JSON into typed objects:
- `Run`
- `Step`
- `FileArtifact`
- `Patch`
- `TestEvent`
- `ErrorEvent`

## Layer 3 — graph compilation
Connect objects using edges:
- run has steps,
- steps point to next steps,
- steps touch files,
- steps create patches,
- steps trigger tests,
- steps raise errors.

## Layer 4 — deterministic analysis
Compute:
- run fingerprints,
- failure priors,
- top files,
- top errors,
- repetition/loop signals,
- patch/test progression signals.

## Layer 5 — clustering
Two-stage clustering:
- coarse motif bucket via deterministic rules,
- subcluster within each bucket using similarity graph.

## Layer 6 — critical-step localization
Find likely pivot steps where the run becomes irrecoverably bad.

## Layer 7 — typed LLM reasoning
Use `by llm()` only for:
- run diagnosis validation,
- cluster naming/summary,
- memory patch synthesis,
- optional query console later.

---

# 7) Context management strategy

## Goal

Support large batches without exploding token usage.

## Multi-resolution memory pyramid

### Level 0 — raw artifacts
Store original files on disk.
Do not send these directly to the LLM.

### Level 1 — normalized step graph
Each step stores canonical fields:
- index,
- role,
- phase,
- excerpt,
- normalized command family,
- touched files,
- patch/test/error indicators,
- return code if available.

### Level 2 — deterministic run features
Each run stores compact structured signals:
- number of steps,
- number of commands,
- number of test actions,
- number of patches,
- number of unique files,
- repeated-step ratio,
- repeated-file ratio,
- first patch step,
- first test step,
- first persistent error step,
- submit-before-recovery flag,
- loop score,
- dominant failure-class priors.

### Level 3 — run digest
Each run gets a deterministic digest of roughly **150–500 tokens**.
It should contain:
- high-level run arc,
- dominant failure signals,
- top files,
- top errors/tests,
- candidate critical steps,
- final outcome.

### Level 4 — cluster digest
Each cluster gets a compact summary:
- size,
- family,
- medoid run,
- recurring signals,
- recurring files/tests/errors,
- draft operational lesson.

### Level 5 — evidence pack
The only thing sent to `by llm()`.

## Hard token budgets

### Per-run diagnosis pack target
- run digest: ~150–250 tokens
- fingerprint summary: ~100–150
- 3 candidate windows: ~600–900 total
- top error/test snippets: ~200–400
- optional similar/contrast run: ~100–200
- prompt + schema instructions: ~250–350

**Target total:** ~1.5k–2.2k tokens

### Per-cluster patch pack target
- cluster stats: ~50–100
- medoid summary: ~150–250
- 2–3 representative run summaries: ~300–500
- recurring signals: ~150–250
- existing rules/prior patch: ~100–200
- prompt + schema instructions: ~250–350

**Target total:** ~1.0k–1.7k tokens

### Hard rule

No LLM call may include an entire trajectory unless used in a one-off debug/dev mode.
The product path must always use compiled evidence.

---

# 8) Step segmentation design

## Why this matters

Bad segmentation will make every later stage noisy.

## Segmentation rule for mini-SWE-agent

Use this as the canonical unit:

> **one assistant turn plus the environment/tool outputs that follow it until the next assistant turn**

This gives a stable “decision step.”

## Step segmentation algorithm

For each trajectory:
1. iterate through messages/history,
2. start a new `Step` at each assistant decision turn,
3. attach following environment/tool/system output to that step until the next assistant turn,
4. compute the step kind/phase from the content.

## Step kinds

Use:
- `SYSTEM`
- `USER`
- `ASSISTANT`
- `COMMAND`
- `EDIT`
- `TEST`
- `SUBMIT`
- `ERROR`
- `OTHER`

## Phase inference rules

Infer `phase` from content:
- search/list/read commands → `inspect`
- diff/edit/apply_patch/write actions → `edit`
- pytest/unit/integration commands → `test`
- final answer/submission content → `submit`
- traceback/import/syntax/failure output → `error`
- otherwise → `reason` or `other`

## Per-step extracted artifacts

Each step should extract:
- commands used,
- normalized command family,
- files mentioned,
- file paths touched,
- patch snippets,
- test names,
- error keywords,
- short excerpt,
- content hash,
- repeat/novelty indicators.

---

# 9) Exact graph schema

## Enums

```jac
enum StepKind {
    SYSTEM,
    USER,
    ASSISTANT,
    TOOL,
    COMMAND,
    EDIT,
    TEST,
    SUBMIT,
    ERROR,
    OTHER
}

enum RunStatus {
    SUBMITTED,
    RESOLVED,
    LIMITS_EXCEEDED,
    INTERRUPTED,
    ERROR_EXIT,
    UNKNOWN
}

enum FailureClass {
    PREMATURE_COMPLETION,
    INVALID_PATCH,
    WRONG_FILE_FOCUS,
    OSCILLATION_LOOP,
    TOOL_MISUSE,
    STALE_CONTEXT_OR_BAD_PLAN,
    REQUIREMENT_DRIFT,
    UNKNOWN
}

enum Severity {
    INFO,
    WARNING,
    ERROR,
    FATAL
}
```

## Nodes

```jac
node Corpus {
    has corpus_id: str;
    has name: str;
    has created_at: str;
}

node Batch {
    has batch_id: str;
    has name: str;
    has source_format: str;
    has subset: str;
    has split: str;
    has created_at: str;
    has run_count: int = 0;
}

node Run {
    has run_id: str;
    has instance_id: str;
    has task_title: str;
    has raw_path: str;
    has exit_status: RunStatus;
    has api_calls: int = 0;
    has cost: float = 0.0;
    has step_count: int = 0;
    has unique_files: int = 0;
    has fingerprint: dict = {};
    has primary_failure: FailureClass = FailureClass.UNKNOWN;
    has cluster_id: str = "";
    has critical_step_idx: int = -1;
    has summary: str = "";
}

node Step {
    has step_id: str;
    has idx: int;
    has kind: StepKind;
    has role: str;
    has phase: str;
    has excerpt: str;
    has raw_offset: int = 0;
    has content_hash: str;
    has repeated: bool = false;
}

node FileArtifact {
    has path: str;
    has basename: str;
    has ext: str;
}

node Patch {
    has patch_id: str;
    has file_path: str;
    has adds: int = 0;
    has dels: int = 0;
    has parse_ok: bool = true;
    has patch_hash: str;
}

node TestEvent {
    has test_id: str;
    has command: str;
    has status: str;
    has failing_tests: list[str] = [];
    has excerpt: str = "";
}

node ErrorEvent {
    has error_id: str;
    has error_type: str;
    has message: str;
    has severity: Severity = Severity.ERROR;
}

node FailureHypothesis {
    has hyp_id: str;
    has label: FailureClass;
    has score: float;
    has rationale: str;
}

node Cluster {
    has cluster_id: str;
    has label: str;
    has failure_class: FailureClass;
    has size: int = 0;
    has medoid_run_id: str = "";
    has summary: str = "";
}

node MemoryPatch {
    has patch_id: str;
    has scope: str;
    has title: str;
    has diff_text: str;
    has confidence: float = 0.0;
}
```

## Edges

```jac
edge HasBatch {}
edge HasRun { has order: int; }
edge HasStep { has order: int; }
edge NextStep {}
edge TouchesFile {}
edge ProducesPatch {}
edge PatchesFile {}
edge RunsTest {}
edge RaisesError {}
edge SupportsHypothesis { has weight: float; }
edge InCluster {}
edge SimilarRun { has score: float; }
edge EvidencedBy {}
edge SuggestsPatch { has weight: float; }
edge ContrastRun { has score: float; }
```

## Why this schema is correct for the MVP

It is intentionally **not** a complete raw-trace mirror.
It is optimized for questions like:
- which runs loop the same way,
- which steps touch the same files,
- where errors start and persist,
- which clusters yield the same operational lesson.

Keep raw file paths so you can always fall back to original artifacts.

---

# 10) Run fingerprint design

Each `Run` gets a compact `fingerprint` dict used for clustering, diagnostics, and UI summaries.

## Required fingerprint fields

```text
num_steps
num_commands
num_tests
num_patches
num_unique_files
repeated_step_ratio
repeated_file_ratio
first_patch_step
first_test_step
first_error_step
first_submit_step
submit_before_recovery
nonzero_return_ratio
loop_score
top_files
top_test_names
top_error_keywords
step_kind_sequence
failure_class_scores
```

## Additional useful derived flags

- `did_any_edit`
- `did_any_test`
- `did_any_patch_parse_fail`
- `did_any_syntax_error`
- `did_any_import_error`
- `ended_in_fail_signal`
- `edited_target_like_files`
- `late_first_edit`
- `late_first_test`

## Purpose of fingerprint

The fingerprint is the compact representation used for:
- deterministic motif scoring,
- run summaries,
- within-bucket similarity,
- critical-step candidate generation.

---

# 11) Clustering strategy

This is one of the most important decisions.

## Do not do this

- no full-trajectory embedding clustering,
- no vector-DB-first pipeline,
- no HDBSCAN rabbit hole as a blocker,
- no opaque clustering that is hard to explain.

## Use two-stage clustering

## Stage A — coarse deterministic failure-family bucketing

Every run gets scored against these top-level failure classes:

1. `PREMATURE_COMPLETION`
2. `INVALID_PATCH`
3. `WRONG_FILE_FOCUS`
4. `OSCILLATION_LOOP`
5. `TOOL_MISUSE`
6. `STALE_CONTEXT_OR_BAD_PLAN`
7. `REQUIREMENT_DRIFT`

The top score becomes the run’s **primary failure family**.

### Example heuristics

#### PREMATURE_COMPLETION
- submission occurs before meaningful test validation,
- submit while last visible signals are still failing,
- very low edit/test effort before submit.

#### INVALID_PATCH
- patch followed by syntax/import/test-collection failure,
- malformed diff or parse failure,
- patch exists but no viable validation path follows.

#### WRONG_FILE_FOCUS
- edits mostly target files weakly related to error/test context,
- multiple edits to files with no visible reduction in target failures.

#### OSCILLATION_LOOP
- repeated command patterns,
- repeated same-file touches,
- high overlap between adjacent steps,
- no progress signals after repeated cycles.

#### TOOL_MISUSE
- repeated nonzero shell/test return codes,
- malformed or irrelevant commands,
- persistent environment misunderstandings.

#### STALE_CONTEXT_OR_BAD_PLAN
- too much generic planning/inspection,
- too little decisive repo interaction,
- long reasoning/search without converging.

#### REQUIREMENT_DRIFT
- changes or searches move away from issue/test target,
- unrelated edits dominate later steps,
- final patch targets non-central files or semantics.

## Stage B — subclustering inside each failure family

Within each coarse family:
1. compute pairwise similarities,
2. add `SimilarRun` edges for top-k neighbors,
3. threshold the similarity graph,
4. take connected components as subclusters.

### Why connected components

This is more Jac-native and easier to explain than stuffing everything into a hidden Python-only clustering stack.

It also maps cleanly to a graph story in the demo:
- runs become nodes,
- similarity becomes edges,
- clusters are connected regions.

## Similarity function

Use a weighted hybrid similarity:

```text
0.35 failure/motif feature overlap
0.20 sequence-pattern similarity
0.20 file/test/error lexical overlap
0.15 numeric feature similarity
0.10 compact-summary text similarity
```

### Concretely

#### Motif feature overlap
Compare:
- dominant failure scores,
- binary flags,
- recovery/non-recovery markers.

#### Sequence-pattern similarity
Compare normalized phase sequences like:
- inspect → edit → test → error → edit → submit
- inspect → inspect → inspect → submit
- inspect → edit → edit → test → error → loop

#### File/test/error overlap
Compare sets or weighted bags of:
- file basenames,
- file extensions,
- test names,
- error keywords.

#### Numeric feature similarity
Compare normalized values of:
- step count,
- patch count,
- repeated-step ratio,
- repeated-file ratio,
- first patch step,
- first test step,
- nonzero-return ratio.

#### Compact-summary similarity
Use TF-IDF or sparse lexical similarity over deterministic run digests.

## Clustering implementation rule

Keep this deterministic and debug-friendly.

Use:
- **top-k neighbor graph** with `k=3..5`,
- similarity threshold like `0.55..0.70`,
- connected components on surviving edges.

Tune with real data during the event.

---

# 12) Critical-step localization strategy

This is the second core algorithm.

## Goal

Find the likely **first irreversible mistake**, not just the final obvious failure.

## Candidate steps

Only score plausible pivot points:
- first patch on a touched file,
- first test after a patch,
- first persistent error step,
- first submit-like step,
- first loop-start step,
- first edit to an off-target file family.

## Candidate window

For each candidate step, build a local evidence window:
- step - 1,
- step,
- step + 1,
with optional expansion to ±2 for sparse runs.

## Heuristic critical score

For each candidate step compute:

```text
critical_score =
    + persistence_of_damage
    + new_error_after_step
    + no_recovery_after_step
    + divergence_from_target_files
    + premature_submit_signal
    + loop_start_signal
    - recovery_signal
```

## Interpretation of features

### persistence_of_damage
After this step, does the run stay “bad” until the end?

### new_error_after_step
Does a major error first appear immediately after this step?

### no_recovery_after_step
Are there no later signals of successful recovery?

### divergence_from_target_files
Did the run begin editing/searching files unrelated to the core issue/test context?

### premature_submit_signal
Did this step or the next step jump toward final submission without validation?

### loop_start_signal
Does repetition explode after this step?

### recovery_signal
If the run later clearly recovers, lower this step’s score.

## Selection rule

Pick the **first** candidate step whose score crosses a threshold and remains part of a bad suffix.
If no step crosses threshold, choose the highest-scoring candidate.

## Role of the LLM

The LLM is a **validator**, not the discoverer.

The heuristic system proposes top 1–3 candidates.
The LLM chooses among them or confirms one.

---

# 13) Structured retrieval strategy

## Do not call this RAG in the design

This is better described as **graph-guided forensic retrieval**.

## Retrieval layers

### Layer 1 — graph retrieval
Use exact structured filters:
- by batch,
- by cluster,
- by failure class,
- by run status,
- by file path,
- by error keyword,
- by test name,
- by model/config.

### Layer 2 — sparse lexical retrieval
Build a simple lexical search layer over:
- run summaries,
- cluster summaries,
- step excerpts,
- generated patches.

Use TF-IDF/BM25 style search.
No vector database.

### Layer 3 — evidence-pack assembly
At diagnosis time assemble:
- run digest,
- fingerprint summary,
- candidate critical windows,
- top files/tests/errors,
- optional similar run,
- optional successful contrast,
- current cluster priors.

That evidence pack is the only thing sent to `by llm()`.

## Optional future RAG use

Only later consider retrieval for:
- prior memory rules from previous batches,
- Jac docs / `candidate.txt` snippets for Jac-specific memory patching.

Do not spend hackathon time on this unless the MVP is already excellent.

---

# 14) Typed LLM objects

Use `by llm()` only with typed structured outputs.

## Diagnosis output

```jac
obj EvidenceRef {
    has step_idx: int;
    has artifact: str;
    has quote: str;
}

obj RunDiagnosis {
    has failure_class: FailureClass;
    has critical_step_idx: int;
    has irreversible_because: str;
    has evidence: list[EvidenceRef];
    has confidence: float;
}
```

## Cluster label output

```jac
obj ClusterLabel {
    has label: str;
    has summary: str;
    has confidence: float;
}
```

## Memory patch output

```jac
obj MemoryRule {
    has title: str;
    has rationale: str;
    has rule_text: str;
    has supported_by_steps: list[int];
    has confidence: float;
}

obj MemoryPatchProposal {
    has scope: str;
    has cluster_label: str;
    has summary: str;
    has rules: list[MemoryRule];
    has diff_text: str;
}
```

## Prompting rules

### For run diagnosis
The model must:
- choose among supplied candidates,
- justify using only provided evidence,
- avoid introducing unsupported assumptions,
- cite evidence steps.

### For cluster labels
The model must:
- name the cluster in operational terms,
- keep the label short and demo-friendly,
- avoid vague phrasing.

### For memory patches
The model must:
- only propose rules supported by repeated evidence,
- prefer operational rules,
- avoid generic advice,
- focus on preventing the specific motif.

---

# 15) `AGENTS.md` patch compiler strategy

This is one of the main differentiators.

## Core rule

Generate patches at the **cluster level first**.

## Why

Cluster-level repeated failure motifs represent stable lessons.
Single-run patches are often too noisy.

## Output requirements

Produce both:
1. human-readable summary,
2. `AGENTS.md` diff block.

## Good patch examples

- “Before submitting, rerun at least one targeted failing test if any test failed earlier.”
- “If the same file has been edited twice without reducing failures, re-rank candidate files using stack trace and failing test names.”
- “Do not submit if the latest visible state still contains syntax/import/test failures.”
- “After two repeated search commands with no new files surfaced, change strategy.”

## Bad patch examples

- “Think harder.”
- “Be careful.”
- “Plan better.”
- “Do more reasoning.”

## Patch compilation flow

1. gather medoid + 2–3 representative runs,
2. gather recurring signals,
3. gather critical-step evidence,
4. generate 2–5 operational rules,
5. render a markdown diff patch,
6. store as `MemoryPatch` node.

---

# 16) Exact walker/function plan

This section is the primary implementation contract for Codex.

## Public API walkers/functions

```jac
walker UploadBatch:pub { ... }
walker LoadSampleBatch:pub { ... }
walker ParseBatch:pub { ... }
walker AnalyzeBatch:pub { ... }
walker GetBatchOverview:pub { ... }
walker GetClusterView:pub { ... }
walker GetRunView:pub { ... }
walker DiagnoseRun:pub { ... }
walker DiagnoseCluster:pub { ... }
walker CompileMemoryPatch:pub { ... }
walker ExportBatchReport:pub { ... }
walker CompareBaseline:pub { ... }
```

## Internal walkers/functions

### `IngestBatchWalker`
Responsibility:
- create batch,
- register raw files,
- create empty run nodes.

### `ParseRunWalker`
Responsibility:
- parse one trajectory JSON,
- segment into steps,
- attach run stats,
- derive step excerpts.

### `LinkArtifactsWalker`
Responsibility:
- extract file mentions,
- extract patch hunks,
- extract test events,
- extract error events,
- link artifacts to steps/runs.

### `FingerprintRunWalker`
Responsibility:
- compute fingerprint dict,
- compute run digest,
- compute step sequence signature.

### `DetectMotifsWalker`
Responsibility:
- compute top-level failure class scores,
- create `FailureHypothesis` nodes,
- set `Run.primary_failure`.

### `BuildSimilarityWalker`
Responsibility:
- compare runs within family,
- add `SimilarRun` edges,
- keep top-k edges only.

### `ClusterRunsWalker`
Responsibility:
- threshold similarity graph,
- compute connected components,
- create cluster nodes,
- assign run-cluster membership.

### `SelectMedoidWalker`
Responsibility:
- pick representative run per cluster,
- choose the run with highest average similarity to cluster members.

### `LocalizeCriticalStepWalker`
Responsibility:
- generate step candidates,
- score candidates,
- choose `Run.critical_step_idx`,
- store evidence windows.

### `ValidateDiagnosisWalker`
Responsibility:
- call `by llm()` with typed schema,
- validate/choose critical step,
- store `RunDiagnosis`.

### `LabelClusterWalker`
Responsibility:
- create short human-friendly label,
- summarize recurring motif.

### `CompilePatchWalker`
Responsibility:
- synthesize cluster-level memory patch,
- render markdown diff.

### `CompareBaselineWalker`
Responsibility:
- run raw compressed trajectory baseline,
- run structured evidence-pack diagnosis,
- store both for demo.

### `ExportReportWalker`
Responsibility:
- export summary report for Devpost/demo backup.

---

# 17) API contract

Codex should implement a clean local API surface.

## Required endpoints

### `POST /upload-batch`
Input:
- zip or folder of trajectories
Output:
- `batch_id`
- run count
- parse status

### `POST /load-sample-batch`
Input:
- sample name or none
Output:
- `batch_id`

### `POST /analyze-batch`
Input:
- `batch_id`
Output:
- analysis status

### `GET /batch/{batch_id}`
Output:
- overview summary,
- family counts,
- clusters,
- top files/errors.

### `GET /cluster/{cluster_id}`
Output:
- cluster label,
- size,
- medoid,
- representative runs,
- recurring signals,
- generated patch.

### `GET /run/{run_id}`
Output:
- run summary,
- timeline,
- critical step,
- diagnosis,
- artifacts.

### `POST /cluster/{cluster_id}/patch`
Output:
- memory patch object,
- diff text.

### `POST /compare-baseline/{run_id}`
Output:
- raw baseline diagnosis,
- structured diagnosis,
- side-by-side fields.

---

# 18) UI layout

Keep the UI simple, fast, and demoable.

## Screen 1 — batch overview

Top row:
- title,
- upload button,
- load sample batch button,
- batch size,
- fail count,
- cluster count.

Main area:
- failure-family chart,
- cluster list,
- top files,
- top error keywords,
- top test names.

## Screen 2 — cluster explorer

Left sidebar:
- clusters,
- failure-family badges,
- size,
- severity/confidence.

Center panel:
- cluster summary,
- medoid run card,
- representative runs,
- recurring signals,
- recurring files/tests/errors.

Right panel:
- generated `AGENTS.md` patch,
- copy/export button,
- confidence,
- bullets of operational lessons.

## Screen 3 — run detail

Top:
- task title,
- status,
- model/config,
- cost/api calls,
- critical-step badge.

Center:
- timeline of steps,
- icons for inspect/edit/test/error/submit,
- critical step highlighted,
- expandable raw excerpts.

Side:
- diagnosis object,
- evidence refs,
- compact fingerprint,
- similar runs,
- optional successful contrast.

## Screen 4 — baseline comparison

Simple side-by-side:
- same run,
- raw-Claude diagnosis,
- structured-evidence diagnosis,
- highlight that the structured version is more specific and cites step evidence.

## Optional screen 5 — query console

Only if time permits.

---

# 19) Repo/file structure

Keep this small and robust.

## Recommended structure

```text
traceforge/
  jac.toml
  main.jac
  py/
    parser.py
    features.py
    similarity.py
    utils.py
  demo_runs/
  uploads/
  exports/
  README.md
  requirements.txt
```

## Why this structure

Use Jac for:
- schema,
- walkers,
- API exposure,
- orchestration,
- `by llm()` typing,
- core traversal logic.

Use Python helper modules only where convenient for:
- JSON parsing,
- regex extraction,
- TF-IDF,
- small math helpers,
- file IO.

## Important note

Do **not** force one-file purity if it harms shipping.
A small multi-file Jac-first app is safer than a brittle single-file stunt.

---

# 20) Concrete implementation phases

Codex should implement in this order.
Do not skip ahead.

## Phase 0 — skeleton and plumbing

### Goal
Get the app booting locally.

### Tasks
- create repo,
- create `jac.toml`,
- create `main.jac`,
- wire `jac start`,
- create simple home screen,
- create placeholder endpoints.

### Done when
- app starts locally,
- sample UI loads,
- public endpoints respond.

## Phase 1 — mini-SWE-agent adapter

### Goal
Parse and load trajectories.

### Tasks
- implement upload/load-sample flow,
- parse `.traj.json`,
- create `Batch` and `Run`,
- store raw artifact path,
- extract run-level metadata,
- segment steps.

### Done when
- 5–10 trajectories can be loaded,
- run timelines render.

## Phase 2 — artifacts and features

### Goal
Extract files/patches/tests/errors and compute fingerprints.

### Tasks
- create `FileArtifact`, `Patch`, `TestEvent`, `ErrorEvent`,
- link them to steps/runs,
- compute run fingerprint,
- compute deterministic run digest,
- compute failure-class priors.

### Done when
- a run page clearly shows files/tests/errors,
- fingerprint JSON exists.

## Phase 3 — coarse motif detection

### Goal
Assign each run to a top-level failure family.

### Tasks
- implement motif heuristics,
- create `FailureHypothesis` nodes,
- store primary failure class,
- render family histogram.

### Done when
- batch overview shows family counts that look plausible.

## Phase 4 — similarity graph and clustering

### Goal
Form meaningful within-family clusters.

### Tasks
- compute pairwise similarities within family,
- keep top-k neighbors,
- add `SimilarRun` edges,
- threshold edges,
- compute connected components,
- create cluster nodes,
- select medoids.

### Done when
- clusters are visible,
- medoid runs look representative.

## Phase 5 — critical-step localization

### Goal
Find likely first irreversible mistakes.

### Tasks
- build candidate step generator,
- compute critical scores,
- select critical step,
- highlight timeline window,
- store evidence bundle.

### Done when
- failed runs show a highlighted pivot step.

## Phase 6 — typed LLM reasoning

### Goal
Use `by llm()` only on compact evidence packs.

### Tasks
- define typed objects,
- implement run diagnosis,
- implement cluster labeler,
- implement patch compiler,
- cache outputs.

### Done when
- run diagnosis appears as structured object,
- cluster patch renders as markdown diff.

## Phase 7 — baseline comparison

### Goal
Create the demo punchline.

### Tasks
- build raw compressed baseline pack,
- build structured evidence pack,
- call same model both ways,
- render side-by-side comparison.

### Done when
- one example clearly shows the value of structure.

## Phase 8 — polish and export

### Goal
Stabilize the demo and submission artifacts.

### Tasks
- add export report,
- add copy patch button,
- add fallback sample loader,
- polish labels,
- remove broken features,
- record demo.

### Done when
- app is stable enough for video and judging.

---

# 21) Hour-by-hour hackathon plan

## Hours 0–2
- lock scope,
- scaffold app,
- start sample trajectory generation,
- wire home page.

## Hours 2–5
- implement parser,
- load sample batch,
- render runs and steps.

## Hours 5–8
- extract artifacts,
- compute fingerprints,
- implement family heuristics.

## Hours 8–11
- implement similarity graph,
- build clusters,
- pick medoids.

## Hours 11–14
- implement critical-step scoring,
- highlight run timeline.

## Hours 14–17
- implement typed `by llm()` diagnosis,
- implement cluster labels,
- implement patch synthesis.

## Hours 17–20
- implement baseline comparison,
- polish cluster/run views,
- test on real data.

## Hours 20–22
- freeze features,
- fix reliability issues,
- capture screenshots.

## Hours 22–24
- record 3-minute demo,
- finalize README and Devpost copy,
- tag release.

---

# 22) Team split

## If 3 people

### Person A — data + graph
- parser,
- schema,
- feature extraction,
- similarity graph,
- critical-step heuristics.

### Person B — Jac app + UI
- app shell,
- upload/load flow,
- batch view,
- cluster view,
- run timeline,
- export/copy UX.

### Person C — LLM + polish
- typed outputs,
- prompt design,
- baseline comparison,
- patch compiler,
- pitch and demo prep.

## If 2 people

### Person A
- parser,
- graph,
- clustering,
- critical-step localization.

### Person B
- app/UI,
- typed LLM objects,
- patch synthesis,
- video/pitch.

---

# 23) Testing and acceptance criteria

## Core acceptance tests

### Test 1 — ingestion
Load sample batch successfully.

### Test 2 — run parsing
At least one run page displays:
- steps,
- files,
- errors/tests,
- summary.

### Test 3 — family assignment
Every run gets a primary failure family.

### Test 4 — clustering
At least 3 nontrivial clusters are visible on a sample dataset.

### Test 5 — critical-step localization
Every failed run has a highlighted critical step.

### Test 6 — diagnosis
At least one structured diagnosis is produced and stored.

### Test 7 — memory patch
At least one cluster emits a coherent `AGENTS.md` patch.

### Test 8 — baseline comparison
At least one example demonstrates a meaningful contrast between raw baseline and structured analysis.

## Quality bar

The diagnosis does not need to be provably perfect.
It does need to be:
- specific,
- auditable,
- step-grounded,
- and clearly more useful than a giant-log summary.

---

# 24) Risk register and cut strategy

## Biggest risks

### Risk 1 — parser mismatch with actual trajectory schema
Mitigation:
- inspect sample files early,
- start with the smallest viable parser,
- store raw message blobs for fallback.

### Risk 2 — clusters are noisy or meaningless
Mitigation:
- keep top-level failure families deterministic,
- use very simple similarity graph logic,
- manually tune threshold on real data.

### Risk 3 — critical-step heuristic is weak
Mitigation:
- score only a small set of plausible pivot steps,
- let the LLM validate among top candidates,
- show evidence windows rather than pretending certainty.

### Risk 4 — typed LLM integration takes too long
Mitigation:
- first store diagnosis as plain dict,
- upgrade to typed object once base flow works,
- cache results.

### Risk 5 — UI takes too long
Mitigation:
- ship a simple dashboard,
- prioritize batch list, cluster list, run view, patch panel.

## Cut order if behind

Cut in this order:
1. query console,
2. nearest successful contrast,
3. fancy charts,
4. dense-embedding experiments,
5. multi-batch comparison,
6. rich exports.

Do **not** cut:
- batch upload/load,
- clustering,
- critical-step highlight,
- one diagnosis,
- one patch,
- one baseline comparison.

---

# 25) Baseline comparison design

This is one of the strongest demo components.

## Principle

Use the **same model** in both conditions.
The point is not model superiority.
The point is the benefit of structure.

## Baseline condition

Input:
- compressed raw trajectory text,
- brief question asking for what went wrong.

Output:
- plain-text summary.

## Structured condition

Input:
- run digest,
- fingerprint,
- candidate critical windows,
- recurring cluster context,
- top files/tests/errors,
- typed output schema.

Output:
- typed diagnosis,
- evidence refs,
- specific critical step,
- optional patch clue.

## Expected pitch line

> “The model is the same in both cases. What changes is the structure and retrieval layer.”

---

# 26) README structure for the repo

Codex should create a clean README with these sections:

1. Project overview
2. Why this exists
3. What it does
4. Why Jac was used
5. Architecture
6. How to run locally
7. Demo flow
8. Limitations
9. Future work

---

# 27) Devpost/writeup skeleton

Use this structure:

## Problem
Coding-agent trajectories are long, repetitive, and difficult to compare across many runs.

## Solution
We built a Jac-native batch failure compiler that turns many trajectories into clustered failure motifs, localizes the first irreversible mistake, and synthesizes reusable memory patches.

## Why Jac
Graph-native data model, walkers for traversal, typed `by llm()` diagnoses, local full-stack app.

## How it works
Upload → parse → graph compile → motif detection → clustering → critical-step localization → patch synthesis.

## What makes it different
Not a trace viewer; it is a failure compiler with repair artifacts.

## What’s next
Broader schema support, Jac-specific Builder/Jac-code modes, historical memory retrieval, and repeated-batch learning.

---

# 28) 3-minute demo script

## 0:00–0:20
“Coding agents generate long, repetitive trajectories, and once you have dozens of runs it becomes extremely hard to tell where they actually fail.”

## 0:20–0:40
“We built a Jac-native batch failure compiler. You upload mini-SWE-agent trajectories, we compile them into a graph, cluster recurring failure motifs, localize the first irreversible mistake, and generate a reusable memory patch like an `AGENTS.md` update.”

## 0:40–1:10
“Here’s the batch overview. On the left are the dominant clusters. This one is premature completion. This one is oscillation on the wrong file. This one is invalid patching after a test failure.”

## 1:10–1:40
“Let’s open one cluster. We show the representative run, the recurring signals, and the critical step window. The red highlight is the likely first irreversible mistake.”

## 1:40–2:05
“Now on the right we show the generated `AGENTS.md` patch. It compiles repeated failures into operational rules like ‘run a targeted test before submit’ or ‘switch strategy after repeated same-file edits without recovery.’”

## 2:05–2:30
“We also compare against a baseline where the same model reads raw compressed trajectory text. The baseline gives a broad summary. Our structured pipeline gives a specific critical step and a reusable memory rule.”

## 2:30–3:00
“Jac was the right tool because the whole system is graph-native: runs, steps, files, patches, tests, and clusters are all first-class nodes; walkers perform the analysis; and `by llm()` returns typed diagnoses and patch proposals. This is not just trace viewing — it is postmortem compilation for coding agents.”

---

# 29) Final coding instructions for Codex

Codex should follow these operating rules:

1. Implement in the phase order listed above.
2. Do not add major features outside MVP before the baseline flow works.
3. Prefer deterministic logic over prompt-heavy logic.
4. Keep all LLM calls small, typed, and cacheable.
5. Keep Jac central in schema, walkers, orchestration, and public API.
6. Use Python helpers only where they save time materially.
7. Keep the UI minimal but clear.
8. Optimize for a stable local demo over completeness.
9. If a choice is ambiguous, choose the version that is easier to explain in a 3-minute demo.
10. If time is tight, cut stretch features before touching clustering, critical-step localization, patch synthesis, or baseline comparison.

---

# 30) Ship criteria

The project is ready to submit when all of these are true:

- local demo runs reliably,
- sample batch loads without manual repair,
- batch overview shows meaningful clusters,
- representative failed run highlights a critical step,
- one cluster emits a good `AGENTS.md` patch,
- one baseline-vs-structured comparison is demoable,
- README is complete,
- demo video recorded,
- repo is public and clean.

it is the long term plan
