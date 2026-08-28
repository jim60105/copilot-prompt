# CI Failure Triage

Turning a log excerpt into a root cause. The goal of every entry here is the *defect*, not the
symptom the runner printed.

## Contents

- [Triage order](#triage-order)
- [Signature to root cause](#signature-to-root-cause)
- [Runner-level failures](#runner-level-failures)
- [Passes locally, fails in CI](#passes-locally-fails-in-ci)
- [Multiple jobs red at once](#multiple-jobs-red-at-once)
- [Green-washing anti-patterns](#green-washing-anti-patterns)

## Triage order

1. **Which job, which step.** A failure in `Set up Python` is a different class of problem from a
   failure in `Run tests`, even when both print `exit code 1`.
2. **Read backwards from `##[error]`.** The annotation marks where the runner noticed; the cause is
   above it.
3. **Find the first failure, not the last.** A cascade of errors usually has one origin, and later
   errors are consequences of it.
4. **Decide: code, config, or environment.** Code failures are in the diff. Config failures are in
   `.github/workflows/`. Environment failures reproduce with an unchanged tree — check whether the
   last green run had the same code (see `references/gh-cli.md`).

## Signature to root cause

| Signature in the log | Usual root cause | Where the fix belongs |
|---|---|---|
| `AssertionError`, `FAILED tests/...`, `expect(...).toBe` | Genuine behaviour change | The code under test, or the assertion if the new behaviour is correct |
| `ModuleNotFoundError`, `Cannot find module`, `ImportError` | Dependency missing from the manifest, or an uncommitted file | Manifest/lockfile, or `git add` the file |
| `error TS####`, `error[E####]`, `cannot find symbol` | Type or compile error not caught locally | The source; check whether the local toolchain version matches CI |
| Lint or format failure (`ruff`, `eslint`, `clippy`, `gofmt`) | Formatter not run before commit, or a rule version bump | Run the project's formatter; if a rule changed, fix the code, not the rule |
| `Could not resolve dependency`, `version solving failed`, `409/429` from a registry | Unpinned or conflicting dependency, or a lockfile that was not regenerated | The lockfile — regenerate it, do not hand-edit |
| `permission denied` writing to a path | Container user mismatch, or a step running as the wrong user | Workflow YAML: permissions, or the container `USER` |
| `Resource not accessible by integration`, `403` from the API | `GITHUB_TOKEN` lacks a scope | The `permissions:` block in the workflow or job |
| `Bad credentials`, `401`, an empty value where a secret is expected | Secret absent, misnamed, or not exposed to fork PRs | Repo/environment settings — **user action**, stop and report |
| `no space left on device` | Runner disk exhausted by images or build artefacts | Free space in the workflow, or split the job |
| `Cache not found`, unexpectedly slow steps | Cache key changed or the cache was evicted | Cache key definition; usually not the failure itself |
| `##[error]The operation was canceled.` | Another job in the matrix failed under `fail-fast`, or `concurrency` cancelled the run | Triage the *other* job, then check whether its defect also hits this one |
| `unable to prepare context`, `failed to solve` (docker) | Containerfile or build context error | The Containerfile or its `context:`/`file:` inputs |
| `Version X of the action is not supported` / deprecation error | An action major version was retired | Pin the action to a supported major version |

## Runner-level failures

These look like infrastructure. They are still defects with real fixes — the loop does not rerun
them away.

| Signal | What actually happened | Real fix |
|---|---|---|
| `exit code 137` | OOM kill (SIGKILL) | Cut peak memory, lower test parallelism, shard the job, or use a larger runner |
| `exit code 143` | SIGTERM — cancelled or timed out | Raise `timeout-minutes`, split the job, or fix the test that hangs |
| `The job running on runner ... has exceeded the maximum execution time` | Job exceeded its timeout | Same as above; find what got slower rather than raising the limit blindly |
| `The runner has received a shutdown signal` | Runner lost, or the whole run was cancelled | Check whether a `concurrency` group cancelled it — a newer push often did |
| Network timeouts to a registry or mirror | Unpinned network dependency in a hot path | Cache the artefact, pin the source, or add a bounded retry to that step |
| Flaky-looking test that passes on retry | A real race, a time or ordering dependency, or shared state between tests | Fix the test's determinism — never mark it as allowed to fail |

## Passes locally, fails in CI

Work through this list before concluding the CI runner is at fault:

- **Toolchain version** — CI pins a version the local machine does not have. Compare the `Set up ...`
  step's resolved version against the local one.
- **Case-sensitive filesystem** — a Linux runner rejects an import that macOS or Windows accepted.
- **Clean checkout** — CI has no local build cache, no untracked file, no stale generated artefact.
  Confirm every needed file is actually committed: `git status --ignored`.
- **Shallow clone** — the default `fetch-depth: 1` breaks anything that reads git history, tags, or
  a merge base.
- **Environment variables** — a local `.env` or shell export that CI does not have.
- **Locale and timezone** — runners default to UTC and `C`/`en_US.UTF-8`.
- **Parallelism** — CI runs tests with different worker counts, exposing shared-state races.
- **Test ordering** — a different seed or shard boundary exposes an inter-test dependency.
- **Network egress** — the runner may not reach a host the local machine can.

## Multiple jobs red at once

The loop batches fixes, so the question is not "which failure do I fix first" but "how many of
these can I fix in this push".

- **Same error in every job** → one shared cause: a broken commit, a bad lockfile, or a workflow-level
  mistake. Fix once, and all of them go green together.
- **One matrix leg red, the rest green** → the leg's own axis is the variable. Diff its version, OS,
  or service container against a passing leg.
- **Different errors in different jobs** → independent causes. Fix them all in this push; they cannot
  mask each other.
- **One real failure plus several cancellations** → `fail-fast: true` cancelled the rest. The
  cancelled jobs are **unknown, not passing**. Check whether the same defect hits them and fix that
  too, rather than discovering it one run later.
- **Steps after the failing step never ran** → their problems are still latent. Read them for
  anything the current change would also break.

## Green-washing anti-patterns

Refuse all of these unless the user explicitly asks for them, and say why:

| Anti-pattern | Why it is worse than red CI |
|---|---|
| Deleting, skipping, or `xfail`-ing the failing test | Removes the signal that something is broken while the breakage remains |
| `continue-on-error: true` on the failing step | Makes the job lie about its outcome forever, not just today |
| Appending `\|\| true` to the failing command | Same, hidden one level deeper where nobody reads it |
| Lowering a coverage or lint threshold to pass | Converts a specific regression into a permanent standards drop |
| Pinning a dependency to dodge a real incompatibility | Defers the break to whoever unpins it, without a record of why |
| Re-running until it happens to pass | Ships the race condition to production |
| Committing a broad `# noqa` / `@ts-ignore` / `#[allow]` | Silences a class of errors to fix one instance |

When the honest fix is genuinely out of scope, stop the loop and report it. A clear "this needs a
token scope change you have to make" is worth more than a green badge over a broken build.
