# Demo Script

## 3-minute draft

### 0:00-0:20

"Coding-agent trajectories are long, repetitive, and hard to compare once you have a batch of failures. TraceForge turns those raw runs into a Jac graph so we can group recurring motifs instead of reading logs one by one."

### 0:20-0:45

"Here is the batch overview. We can switch between sample and uploaded mini-SWE-agent batches. The app shows the leading failure families, top files, top errors, and the clusters that were compiled from the run graph."

### 0:45-1:20

"Now we open one recurring cluster. Instead of a log viewer, we see the medoid run, recurring signals, recurring files, recurring tests, and a reusable AGENTS.md patch synthesized from that repeated motif."

### 1:20-1:55

"Next we open a representative failed run. The timeline is segmented into decision steps, the likely first irreversible step is highlighted, and the diagnosis cites the critical evidence window rather than the whole trajectory."

### 1:55-2:25

"On the bottom we compare the same run under two conditions. The raw baseline only sees compressed trajectory text. The structured path sees a graph-backed evidence pack. The point is not a stronger model. The point is better structure."

### 2:25-3:00

"Jac is central here: the schema is graph-native, walkers expose the API, the app UI is in Jac, and typed by llm() calls can validate diagnoses and synthesize patches when credentials are available. This is postmortem compilation for coding agents, not just trace browsing."

## Demo order

1. Open the starter batch.
2. Show the batch overview and family counts.
3. Open the first cluster and read one recurring signal aloud.
4. Open the medoid run and point to the critical-step window.
5. Show the generated AGENTS.md patch.
6. Finish on the baseline comparison.
