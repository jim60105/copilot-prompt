---
name: fix-ci-until-green
description: Drive a failing GitHub Actions run to green in as few CI runs as possible, with a bounded fix-critique-commit-push-recheck loop that batches every evidenced fix into each push. Use when the user supplies a GitHub Actions run URL or run ID and wants the failure fixed, or asks to "make CI green", "fix the failing workflow/build/tests", "fix the red build", or to keep iterating on a branch or pull request until its checks pass. Pulls run results and failed-job logs through the gh CLI, and sends every fix plan to the rubber-duck reviewer before any code is touched.
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Fix CI Until Green

Take a red GitHub Actions run and iterate until it is green: read every failure, form root-cause
hypotheses, get the plan critiqued, fix, commit, push, read the next run. Repeat.

**Optimise for the fewest CI runs, not the smallest diff.** Every push spends real runner time, so
each iteration should try to fix *everything* wrong with the branch — including failures that are
still hidden behind the ones CI reported.

**Hard cap: 10 iterations.** Report and hand control back when the cap is reached.

## Prerequisites

Verify before the first iteration:

- `gh auth status` succeeds and `jq` is installed — both scripts depend on them.
- The working tree is clean, or the pending changes are understood and intended to ship.
- `git rev-parse --abbrev-ref HEAD` and `git remote -v` point at the branch and repo whose CI is failing.

## Loop Invariants

These hold in **every** iteration. Violating one turns a fixed build into a hidden regression.

- **Fix the cause, never the check.** Deleting, skipping, or `xfail`-ing a test, adding
  `continue-on-error`, appending `|| true`, lowering a coverage or lint threshold, or pinning around
  a real breakage are all forbidden unless the user explicitly asks for them.
- **Every failure is a real defect.** Do not write anything off as flaky and do not `gh run rerun`
  to make it disappear. Timeouts, OOM kills, and registry errors have real causes and real fixes —
  see `references/failure-triage.md`.
- **Fix everything you can see, in one push.** Each iteration costs a full CI run, so the goal is
  the fewest runs to green, not the smallest diff per run. Triage *every* failing job, fix *every*
  cause the evidence supports, and push them together.
- **Batch evidenced fixes; never batch guesses.** Two fixes for two different failures both belong
  in this push. Two competing hypotheses for the *same* failure do not — stacking alternatives means
  the next run cannot tell you which one was right. Pick the best-supported one and note the other
  in the ledger.
- **The plan is critiqued before any edit.** No exceptions, no "this one is obvious".
- **Append-only history.** Never `--force` push, and never amend or rebase a commit that is already
  pushed. Each iteration is one new commit.

## Step 0 — Resolve the target

The user supplies a run URL or a bare run ID. Both forms are accepted directly by the scripts;
`https://github.com/OWNER/REPO/actions/runs/ID` also carries the repo, so `-R` is only needed for a
bare ID outside the target repository.

Given a PR instead of a run, get to the run first: `gh pr checks <pr>` or
`gh run list --branch <branch> --limit 10`. See `references/gh-cli.md`.

## Step 1 — Read the failure

```bash
scripts/ci_failure_report.sh <run-url-or-id> [-R OWNER/REPO]
```

Reports **every failure in every failed job**, which is what the batching policy needs. Per job it
prints the failed steps, then:

- **Failure blocks** — one full body per distinct failure. Repeats collapse to one representative
  plus the complete list of their variants, so ten near-identical assertions stay readable without
  losing any single identifier.
- **Other error lines** — annotations and failure keywords from elsewhere in the log, filtered
  against the blocks so nothing is printed twice.
- **Log excerpt** — the narrative around `##[error]`, read backwards, for failures no test framework
  reported.

Every cap announces what it hid (`... N more ... hidden`). If you see such a line, the failure set is
incomplete — raise `--block-lines`, `--max-blocks`, or `--signature-lines` and re-read before
planning, rather than fixing a subset.

| Exit | Meaning | Next |
|---|---|---|
| 0 | Run is green | Loop is done — go to **Reporting** |
| 1 | Run failed, report printed | Continue to Step 2 |
| 2 | Still queued or running | Wait (Step 6), then re-read |
| 3 | Bad reference, auth, or lookup error | Fix the invocation; do not guess at a fix |

When the excerpt is not enough — the error is far from the annotation, or a matrix leg needs
comparing against a green leg — pull the full job log and related evidence using the recipes in
`references/gh-cli.md`.

## Step 2 — Triage into a root-cause hypothesis

Read `references/failure-triage.md` for signature-to-cause mappings and the "only fails in CI"
checklist.

Before moving on, be able to state all four:

1. The failing **job and step**.
2. The **decisive log line**, quoted verbatim.
3. The **root cause** — the defect itself, not the symptom the runner reported.
4. The **smallest change** that removes that cause.

Do this for **every** failing job in the run, not just the first one the report prints.

Then look for the failures CI has not reported yet — finding them now saves a whole round trip:

- **Cancelled siblings.** Under `fail-fast: true`, one red leg cancels the rest. Those legs are
  unknown, not passing. Assume the same defect hits them and check.
- **Steps that never ran.** Everything after the failing step was skipped, so its problems are still
  latent. Read the remaining steps for anything the same change would break.
- **The same defect elsewhere.** If a rename broke one import, grep for the other call sites now.

If the evidence does not support a clear hypothesis for a given failure, gather more before acting:
read the workflow YAML, read the source the log points at, and diff against the last green run
(`references/gh-cli.md`). A guess costs a full run and pollutes the next iteration's signal.

## Step 3 — Critique the plan (mandatory, every iteration)

Invoke the **`rubber-duck` skill** and follow its instructions for constructing the message,
waiting for the verdict, and interpreting the tiers. Do not proceed to Step 4 until the review has
come back and every blocking finding is resolved.

On top of what that skill requires, this loop's message must carry:

- The run URL, **every** failing job and step, and the decisive log lines **verbatim**.
- One root-cause hypothesis per failure, with the specific evidence that supports each.
- The exact edits planned for the whole batch, as real code or a real diff.
- Any latent failure you predicted and are pre-emptively fixing, and why you expect it.
- **The iteration ledger so far** — what was already tried and what CI said about it. Without it the
  reviewer cannot see that an approach has already been ruled out.
- Targeted questions, at minimum: *"Does each fix address the root cause, or only the symptom CI
  reported?"* and *"Do any of these fixes interact badly with each other?"* — batched changes can
  conflict in ways individually-correct fixes do not.

Redact tokens and secrets from log excerpts before pasting them.

## Step 4 — Apply the fix

Apply the whole cleared batch. If the review changed the approach materially, re-run Step 3 on the
revised plan rather than improvising.

**Local verification follows the project's own instructions.** Check `AGENTS.md`, `CLAUDE.md`,
`CONTRIBUTING.md`, or the README for how this project expects lint, tests, and builds to be run, and
do exactly that. This skill prescribes no commands of its own. If the project documents nothing,
do not invent a suite — push and let CI judge.

When the project does document a suite, running it here is the cheapest check available: a batched
push multiplies the cost of a mistake, and a local run catches fixes that broke each other before
they cost a CI round trip.

## Step 5 — Commit and push

Follow the **`commit` skill** for message format. Split the batch into as many commits as the
history deserves — one per logical fix reads better than one omnibus commit — but **push once**.
The push is what spends a CI run, so everything from this iteration goes up together.

```bash
git add <paths>          # stage deliberately, not -A
git commit               # per the commit skill; repeat per logical fix
git push                 # once, current branch, no force, no branch juggling
```

Record the pushed HEAD SHA — Step 6 watches that exact commit.

## Step 6 — Wait for the new run, then read it

```bash
scripts/wait_for_ci.sh [--sha <pushed-sha>] [-R OWNER/REPO]
```

Waits for every run attached to the commit to finish. **Run it in the background** if the harness
blocks long-running foreground commands.

| Exit | Meaning | Next |
|---|---|---|
| 0 | Every run passed | Loop is done — go to **Reporting** |
| 1 | Something failed; failing run IDs printed | Back to Step 1 with those IDs |
| 2 | Timed out with runs still going | Extend `--timeout` and wait again; do not start editing |
| 3 | No run registered for the commit | Diagnose with `references/gh-cli.md` before assuming success |

Exit 3 is never "green". A commit with no run is an unverified commit.

## Termination

Stop and report when any of these is true:

- **Green** — every run for the pushed commit passed.
- **Cap reached** — 10 iterations completed without green.
- **Blocked** — the fix needs something outside your reach: a secret, a token scope, a repo or
  branch setting, a third-party outage, or a product decision that belongs to the user.
- **No progress** — the same root cause survives three consecutive iterations. The approach is
  wrong, not under-applied. Stop, and bring the ledger to the user instead of an eleventh guess.
  A batch that fixes some failures while others persist unchanged still counts as progress; a batch
  that changes nothing about the failure set does not.

## Iteration ledger

Maintain this table across the whole loop, one row per failure fixed. It feeds Step 3 and the final
report, and it is what keeps iteration 7 from re-trying what iteration 2 already disproved.

| # | Run | Failing job / step | Root cause hypothesis | Fix applied | CI verdict |
|---|---|---|---|---|---|
| 1 | 33134020988 | top-level / regression suite | new browser test not registered in any process list | added it to the browser process list | green |
| 1 | 33134020988 | top-level / regression suite | 10 new `inventory-panel*` targets missing from the frozen audit §2.3 list | added all 10 targets | green |
| 1 | 33134020988 | docs (cancelled by fail-fast) | predicted latent: same rename breaks the docs reference | updated the reference pre-emptively | green |

Also record the hypotheses you *rejected* while batching. A competing explanation that was passed
over is exactly what iteration 2 needs when the first choice turns out wrong.

## Reporting

Close with, in 正體中文:

- The outcome: green, stopped at the cap, or blocked — and for the last two, exactly what remains red.
- The ledger, so the user sees what was tried and ruled out.
- The commits pushed, and the final run URL.
- For a blocked stop: the specific action the user needs to take.

Never report green without a run that concluded `success` for the pushed commit.

## Reference files

- `references/gh-cli.md` — gh recipes for resolving runs, pulling full logs, annotations, comparing
  against the last green run, and the CLI pitfalls that produce misleading output.
- `references/failure-triage.md` — log signature to root cause across ecosystems, the
  "passes locally, fails in CI" checklist, and the green-washing anti-patterns to refuse.
